"""
Inference client for testing fraud detection model.
Tests latency, throughput, and accuracy of the deployed KServe model.
"""

import argparse
import concurrent.futures
import json
import time
from typing import List, Dict, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime
import random
import numpy as np

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


@dataclass
class InferenceMetrics:
    """Metrics for a single inference request."""
    request_time: float  # microseconds
    inference_time: float  # microseconds
    total_time: float  # microseconds
    success: bool
    error_message: str = None
    timestamp: str = None


class InferenceClient:
    """Client for testing fraud detection inference."""
    
    def __init__(
        self,
        endpoint: str,
        timeout: int = 30,
        enable_retry: bool = True,
    ):
        """
        Initialize inference client.
        
        Args:
            endpoint: KServe endpoint URL
            timeout: Request timeout in seconds
            enable_retry: Enable automatic retries
        """
        self.endpoint = endpoint
        self.timeout = timeout
        self.session = requests.Session()
        
        if enable_retry:
            retry_strategy = Retry(
                total=3,
                backoff_factor=1,
                status_forcelist=[429, 500, 502, 503, 504],
            )
            adapter = HTTPAdapter(max_retries=retry_strategy)
            self.session.mount("http://", adapter)
            self.session.mount("https://", adapter)
    
    def generate_sample_transaction(self) -> Dict:
        """Generate a sample transaction for testing."""
        return {
            "amount": float(np.random.lognormal(4.5, 1.5)),
            "merchant_id": random.randint(1, 1000),
            "country": random.randint(1, 50),
            "hour": random.randint(0, 23),
            "day_of_week": random.randint(0, 6),
            "day_of_month": random.randint(1, 28),
            "is_night": 1 if random.randint(0, 23) < 6 else 0,
            "is_weekend": random.randint(0, 1),
            "log_amount": np.log1p(float(np.random.lognormal(4.5, 1.5))),
            "amount_squared": float(np.random.lognormal(4.5, 1.5)) ** 2,
            "high_amount": 1 if np.random.uniform() > 0.75 else 0,
            "unusual_time": random.randint(0, 1),
            "high_risk_device": random.randint(0, 1),
            "high_risk_transaction": random.randint(0, 1),
            "total_risk_factors": random.randint(0, 4),
        }
    
    def prepare_request_payload(self, transaction: Dict) -> Dict:
        """Prepare request payload for KServe."""
        # Get feature names in correct order
        feature_names = [
            "amount", "merchant_id", "country", "hour", "day_of_week",
            "day_of_month", "is_night", "is_weekend", "log_amount",
            "amount_squared", "high_amount", "unusual_time",
            "high_risk_device", "high_risk_transaction", "total_risk_factors"
        ]
        
        # Create request in KServe format (V2 protocol)
        payload = {
            "inputs": [
                {
                    "name": "float_input",
                    "shape": [1, len(feature_names)],
                    "datatype": "FP32",
                    "data": [[transaction[name] for name in feature_names]]
                }
            ]
        }
        
        return payload
    
    def predict(self, transaction: Dict) -> Tuple[bool, InferenceMetrics]:
        """
        Make a prediction for a single transaction.
        
        Returns:
            (success, metrics)
        """
        request_start = time.time()
        
        try:
            payload = self.prepare_request_payload(transaction)
            
            inference_start = time.time()
            
            response = self.session.post(
                f"{self.endpoint}/v2/models/fraud_detector/infer",
                json=payload,
                timeout=self.timeout,
            )
            
            inference_end = time.time()
            request_end = time.time()
            
            response.raise_for_status()
            
            # Extract fraud probability from response
            result = response.json()
            fraud_score = result["outputs"][0]["data"][0]
            
            metrics = InferenceMetrics(
                request_time=(inference_start - request_start) * 1e6,
                inference_time=(inference_end - inference_start) * 1e6,
                total_time=(request_end - request_start) * 1e6,
                success=True,
                timestamp=datetime.now().isoformat(),
            )
            
            return (fraud_score > 0.5, metrics)
        
        except Exception as e:
            request_end = time.time()
            
            metrics = InferenceMetrics(
                request_time=(request_start - request_start) * 1e6,
                inference_time=0,
                total_time=(request_end - request_start) * 1e6,
                success=False,
                error_message=str(e),
                timestamp=datetime.now().isoformat(),
            )
            
            return (False, metrics)
    
    def run_throughput_test(
        self,
        num_requests: int = 1000,
        concurrent_clients: int = 10,
    ) -> Dict:
        """
        Run throughput test with concurrent requests.
        
        Args:
            num_requests: Total requests to send
            concurrent_clients: Number of concurrent requests
        
        Returns:
            Test results dictionary
        """
        print(f"\nRunning throughput test...")
        print(f"  Requests: {num_requests}")
        print(f"  Concurrent clients: {concurrent_clients}")
        
        metrics_list = []
        start_time = time.time()
        
        def worker(request_id):
            transaction = self.generate_sample_transaction()
            _, metrics = self.predict(transaction)
            return metrics
        
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=concurrent_clients
        ) as executor:
            futures = [
                executor.submit(worker, i)
                for i in range(num_requests)
            ]
            
            for i, future in enumerate(concurrent.futures.as_completed(futures)):
                metrics = future.result()
                metrics_list.append(metrics)
                
                if (i + 1) % 100 == 0:
                    print(f"  Processed: {i + 1}/{num_requests}")
        
        end_time = time.time()
        
        # Calculate statistics
        successful = [m for m in metrics_list if m.success]
        failed = [m for m in metrics_list if not m.success]
        
        total_times = [m.total_time for m in successful]
        inference_times = [m.inference_time for m in successful]
        
        results = {
            "test_type": "throughput",
            "num_requests": num_requests,
            "concurrent_clients": concurrent_clients,
            "successful_requests": len(successful),
            "failed_requests": len(failed),
            "success_rate": len(successful) / num_requests * 100,
            "total_duration_seconds": end_time - start_time,
            "throughput_rps": num_requests / (end_time - start_time),
            "latency": {
                "min_ms": np.percentile(total_times, 0) / 1000,
                "p50_ms": np.percentile(total_times, 50) / 1000,
                "p95_ms": np.percentile(total_times, 95) / 1000,
                "p99_ms": np.percentile(total_times, 99) / 1000,
                "max_ms": np.percentile(total_times, 100) / 1000,
                "mean_ms": np.mean(total_times) / 1000,
                "stdev_ms": np.std(total_times) / 1000,
            },
            "inference_latency": {
                "min_ms": np.percentile(inference_times, 0) / 1000,
                "p50_ms": np.percentile(inference_times, 50) / 1000,
                "p95_ms": np.percentile(inference_times, 95) / 1000,
                "p99_ms": np.percentile(inference_times, 99) / 1000,
                "max_ms": np.percentile(inference_times, 100) / 1000,
                "mean_ms": np.mean(inference_times) / 1000,
            }
        }
        
        return results
    
    def run_latency_test(self, num_requests: int = 100) -> Dict:
        """
        Run latency test with sequential requests.
        
        Args:
            num_requests: Number of requests
        
        Returns:
            Test results dictionary
        """
        print(f"\nRunning latency test...")
        print(f"  Sequential requests: {num_requests}")
        
        metrics_list = []
        start_time = time.time()
        
        for i in range(num_requests):
            transaction = self.generate_sample_transaction()
            _, metrics = self.predict(transaction)
            metrics_list.append(metrics)
            
            if (i + 1) % 20 == 0:
                print(f"  Completed: {i + 1}/{num_requests}")
        
        end_time = time.time()
        
        # Calculate statistics
        successful = [m for m in metrics_list if m.success]
        total_times = [m.total_time for m in successful]
        
        results = {
            "test_type": "latency",
            "num_requests": num_requests,
            "successful_requests": len(successful),
            "failed_requests": num_requests - len(successful),
            "latency_ms": {
                "min": np.min(total_times) / 1000,
                "p50": np.percentile(total_times, 50) / 1000,
                "p95": np.percentile(total_times, 95) / 1000,
                "p99": np.percentile(total_times, 99) / 1000,
                "max": np.max(total_times) / 1000,
                "mean": np.mean(total_times) / 1000,
                "stdev": np.std(total_times) / 1000,
            }
        }
        
        return results


def print_results(results: Dict) -> None:
    """Pretty print test results."""
    print("\n" + "=" * 60)
    print(f"TEST RESULTS: {results['test_type'].upper()}")
    print("=" * 60)
    
    if results["test_type"] == "throughput":
        print(f"\nRequests:")
        print(f"  Total: {results['num_requests']}")
        print(f"  Concurrent clients: {results['concurrent_clients']}")
        print(f"  Successful: {results['successful_requests']}")
        print(f"  Failed: {results['failed_requests']}")
        print(f"  Success rate: {results['success_rate']:.1f}%")
        
        print(f"\nThroughput:")
        print(f"  Requests/sec: {results['throughput_rps']:.0f} RPS")
        print(f"  Total duration: {results['total_duration_seconds']:.1f}s")
        
        print(f"\nLatency (milliseconds):")
        latency = results["latency"]
        print(f"  Min:    {latency['min_ms']:8.2f} ms")
        print(f"  p50:    {latency['p50_ms']:8.2f} ms")
        print(f"  p95:    {latency['p95_ms']:8.2f} ms")
        print(f"  p99:    {latency['p99_ms']:8.2f} ms")
        print(f"  Max:    {latency['max_ms']:8.2f} ms")
        print(f"  Mean:   {latency['mean_ms']:8.2f} ms (±{latency['stdev_ms']:.2f})")
        
        print(f"\nInference Latency (milliseconds):")
        inf_latency = results["inference_latency"]
        print(f"  Min:    {inf_latency['min_ms']:8.2f} ms")
        print(f"  p50:    {inf_latency['p50_ms']:8.2f} ms")
        print(f"  p95:    {inf_latency['p95_ms']:8.2f} ms")
        print(f"  p99:    {inf_latency['p99_ms']:8.2f} ms")
        print(f"  Max:    {inf_latency['max_ms']:8.2f} ms")
    
    else:  # latency test
        print(f"\nRequests:")
        print(f"  Total: {results['num_requests']}")
        print(f"  Successful: {results['successful_requests']}")
        print(f"  Failed: {results['failed_requests']}")
        
        print(f"\nLatency (milliseconds):")
        latency = results["latency_ms"]
        print(f"  Min:    {latency['min']:8.2f} ms")
        print(f"  p50:    {latency['p50']:8.2f} ms")
        print(f"  p95:    {latency['p95']:8.2f} ms")
        print(f"  p99:    {latency['p99']:8.2f} ms")
        print(f"  Max:    {latency['max']:8.2f} ms")
        print(f"  Mean:   {latency['mean']:8.2f} ms (±{latency['stdev']:.2f})")
    
    print("=" * 60)


def main():
    parser = argparse.ArgumentParser(
        description="Test fraud detection model inference"
    )
    parser.add_argument(
        "--endpoint",
        type=str,
        required=True,
        help="KServe endpoint URL (e.g., http://fraud-detection-svc:8000)",
    )
    parser.add_argument(
        "--test-type",
        type=str,
        choices=["latency", "throughput", "both"],
        default="both",
        help="Type of test to run",
    )
    parser.add_argument(
        "--requests",
        type=int,
        default=1000,
        help="Number of requests for throughput test",
    )
    parser.add_argument(
        "--concurrent",
        type=int,
        default=10,
        help="Number of concurrent clients",
    )
    parser.add_argument(
        "--output",
        type=str,
        help="Save results to JSON file",
    )
    
    args = parser.parse_args()
    
    # Create client
    client = InferenceClient(endpoint=args.endpoint)
    
    results = []
    
    # Run tests
    if args.test_type in ["latency", "both"]:
        latency_results = client.run_latency_test(num_requests=100)
        print_results(latency_results)
        results.append(latency_results)
    
    if args.test_type in ["throughput", "both"]:
        throughput_results = client.run_throughput_test(
            num_requests=args.requests,
            concurrent_clients=args.concurrent,
        )
        print_results(throughput_results)
        results.append(throughput_results)
    
    # Save results if requested
    if args.output:
        with open(args.output, "w") as f:
            json.dump(results, f, indent=2)
        print(f"\nResults saved to {args.output}")


if __name__ == "__main__":
    main()
