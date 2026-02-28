"""
Generate synthetic transaction data for fraud detection model training.
Simulates realistic transaction patterns with fraud distribution.
"""

import argparse
import json
import random
from datetime import datetime, timedelta
from pathlib import Path

import boto3
import numpy as np
import pandas as pd
from typing import Tuple, List

# Configuration
FRAUD_RATE = 0.05  # 5% fraud rate (realistic)
NUM_MERCHANTS = 1000
NUM_COUNTRIES = 50
DEVICE_TYPES = ["phone", "desktop", "tablet", "unknown"]
TRANSACTION_TYPES = ["card_present", "card_not_present", "online", "atm"]


def generate_transaction_amounts() -> float:
    """Generate realistic transaction amounts (log-normal distribution)."""
    # Most transactions are small, some are large
    amount = np.random.lognormal(mean=4.5, sigma=1.5)
    return round(max(1, min(10000, amount)), 2)


def generate_fraud_features() -> Tuple[float, int, int, str, str]:
    """Generate features for fraudulent transaction."""
    # Fraudulent transactions have different patterns
    amount = np.random.lognormal(mean=5.5, sigma=1.2)  # Higher average
    amount = round(max(100, min(50000, amount)), 2)
    
    merchant_id = random.randint(1, NUM_MERCHANTS)
    country = random.choice(list(range(1, NUM_COUNTRIES + 1)))
    
    # Fraudsters use specific device types
    device_type = random.choice(["desktop", "unknown"])
    transaction_type = random.choice(["card_not_present", "online"])
    
    return amount, merchant_id, country, device_type, transaction_type


def generate_legitimate_features() -> Tuple[float, int, int, str, str]:
    """Generate features for legitimate transaction."""
    amount = generate_transaction_amounts()
    
    merchant_id = random.randint(1, NUM_MERCHANTS)
    country = random.randint(1, NUM_COUNTRIES)
    
    device_type = random.choice(DEVICE_TYPES)
    transaction_type = random.choice(TRANSACTION_TYPES)
    
    return amount, merchant_id, country, device_type, transaction_type


def get_time_of_day_score(timestamp: datetime) -> float:
    """Calculate risk score based on time of day (0-1)."""
    hour = timestamp.hour
    # Risk is higher at night (0-6 AM)
    if 0 <= hour < 6:
        return 0.8
    elif 6 <= hour < 9:
        return 0.3
    elif 9 <= hour < 17:
        return 0.1
    elif 17 <= hour < 21:
        return 0.2
    else:
        return 0.6


def calculate_risk_score(
    amount: float,
    merchant_id: int,
    country: int,
    device_type: str,
    transaction_type: str,
    hour_score: float,
) -> float:
    """Calculate combined risk score (0-1)."""
    score = 0.0
    
    # Amount risk
    if amount > 5000:
        score += 0.3
    elif amount > 1000:
        score += 0.1
    
    # Device risk
    if device_type == "unknown":
        score += 0.2
    elif device_type == "phone":
        score += 0.05
    
    # Transaction type risk
    if transaction_type == "card_not_present":
        score += 0.15
    elif transaction_type == "online":
        score += 0.1
    
    # Time of day
    score += hour_score * 0.15
    
    # Merchant risk (simulated)
    if merchant_id % 7 == 0:  # Some merchants are riskier
        score += 0.1
    
    return min(1.0, score)


def generate_dataset(num_samples: int) -> pd.DataFrame:
    """Generate synthetic transaction dataset."""
    print(f"Generating {num_samples} synthetic transactions...")
    
    transactions = []
    base_time = datetime.now() - timedelta(days=30)
    
    num_fraud = int(num_samples * FRAUD_RATE)
    num_legitimate = num_samples - num_fraud
    
    # Generate legitimate transactions
    for i in range(num_legitimate):
        timestamp = base_time + timedelta(
            seconds=random.randint(0, 30 * 24 * 3600)
        )
        amount, merchant_id, country, device_type, transaction_type = (
            generate_legitimate_features()
        )
        hour_score = get_time_of_day_score(timestamp)
        
        risk_score = calculate_risk_score(
            amount, merchant_id, country, device_type, transaction_type, hour_score
        )
        
        # Use risk score as fraud indicator (threshold at 0.7)
        is_fraud = 1 if risk_score > 0.7 else 0
        
        transactions.append({
            "transaction_id": f"TXN_{i:010d}",
            "timestamp": timestamp.isoformat(),
            "amount": amount,
            "merchant_id": merchant_id,
            "country": country,
            "device_type": device_type,
            "transaction_type": transaction_type,
            "hour": timestamp.hour,
            "day_of_week": timestamp.weekday(),
            "is_fraud": is_fraud,
        })
    
    # Generate fraud transactions
    for i in range(num_fraud):
        timestamp = base_time + timedelta(
            seconds=random.randint(0, 30 * 24 * 3600)
        )
        amount, merchant_id, country, device_type, transaction_type = (
            generate_fraud_features()
        )
        hour_score = get_time_of_day_score(timestamp)
        
        transactions.append({
            "transaction_id": f"TXN_{(num_legitimate + i):010d}",
            "timestamp": timestamp.isoformat(),
            "amount": amount,
            "merchant_id": merchant_id,
            "country": country,
            "device_type": device_type,
            "transaction_type": transaction_type,
            "hour": timestamp.hour,
            "day_of_week": timestamp.weekday(),
            "is_fraud": 1,
        })
    
    # Shuffle
    random.shuffle(transactions)
    
    df = pd.DataFrame(transactions)
    print(f"Generated {len(df)} transactions with {df['is_fraud'].sum()} frauds")
    print(f"Fraud rate: {df['is_fraud'].mean():.2%}")
    
    return df


def save_to_s3(df: pd.DataFrame, s3_path: str) -> None:
    """Save dataframe to S3."""
    # Parse S3 path
    if not s3_path.startswith("s3://"):
        raise ValueError("S3 path must start with s3://")
    
    s3_path_parts = s3_path.replace("s3://", "").split("/", 1)
    bucket = s3_path_parts[0]
    key = s3_path_parts[1] if len(s3_path_parts) > 1 else "transactions.csv"
    
    if not key.endswith(".csv"):
        key = f"{key}/transactions.csv"
    
    print(f"Uploading to s3://{bucket}/{key}...")
    
    s3_client = boto3.client("s3")
    
    # Convert to CSV in memory
    csv_buffer = df.to_csv(index=False)
    
    s3_client.put_object(
        Bucket=bucket,
        Key=key,
        Body=csv_buffer,
        ContentType="text/csv",
    )
    
    print(f"Successfully uploaded to s3://{bucket}/{key}")


def save_locally(df: pd.DataFrame, output_path: str) -> None:
    """Save dataframe locally."""
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    df.to_csv(output_path, index=False)
    print(f"Saved to {output_path}")
    
    # Print statistics
    print("\nDataset Statistics:")
    print(f"Total transactions: {len(df)}")
    print(f"Fraud transactions: {df['is_fraud'].sum()}")
    print(f"Fraud rate: {df['is_fraud'].mean():.2%}")
    print(f"Amount range: ${df['amount'].min():.2f} - ${df['amount'].max():.2f}")
    print(f"Average amount: ${df['amount'].mean():.2f}")
    print(f"\nDevice types:")
    print(df["device_type"].value_counts())
    print(f"\nTransaction types:")
    print(df["transaction_type"].value_counts())


def main():
    parser = argparse.ArgumentParser(
        description="Generate synthetic transaction data"
    )
    parser.add_argument(
        "--num-samples",
        type=int,
        default=100000,
        help="Number of transactions to generate (default: 100000)",
    )
    parser.add_argument(
        "--output-path",
        type=str,
        required=True,
        help="Output path (local or S3 path starting with s3://)",
    )
    
    args = parser.parse_args()
    
    # Generate data
    df = generate_dataset(args.num_samples)
    
    # Save data
    if args.output_path.startswith("s3://"):
        save_to_s3(df, args.output_path)
    else:
        save_locally(df, args.output_path)


if __name__ == "__main__":
    main()
