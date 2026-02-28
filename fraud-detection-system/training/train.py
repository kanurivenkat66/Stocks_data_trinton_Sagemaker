"""
SageMaker training script for fraud detection model.
Supports XGBoost and LightGBM with optimization for fast inference.
"""

import argparse
import json
import json
import os
import pickle
from typing import Tuple, Dict, Any

import joblib
import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.metrics import (
    auc,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
    roc_curve,
)


class FraudDetectionModel:
    """Wrapper for fraud detection model."""
    
    def __init__(self, model_type: str = "xgboost"):
        self.model_type = model_type
        self.model = None
        self.feature_names = None
        self.feature_importance = None
    
    def train(
        self,
        X_train: np.ndarray,
        y_train: np.ndarray,
        X_val: np.ndarray,
        y_val: np.ndarray,
        hyperparameters: Dict[str, Any],
    ) -> Dict[str, float]:
        """Train the model."""
        if self.model_type == "xgboost":
            return self._train_xgboost(X_train, y_train, X_val, y_val, hyperparameters)
        else:
            raise ValueError(f"Unknown model type: {self.model_type}")
    
    def _train_xgboost(
        self,
        X_train: np.ndarray,
        y_train: np.ndarray,
        X_val: np.ndarray,
        y_val: np.ndarray,
        hyperparameters: Dict[str, Any],
    ) -> Dict[str, float]:
        """Train XGBoost model for production inference."""
        print("Training XGBoost model...")
        
        dtrain = xgb.DMatrix(X_train, label=y_train)
        dval = xgb.DMatrix(X_val, label=y_val)
        
        # Extract hyperparameters
        params = {
            "max_depth": hyperparameters.get("max_depth", 6),
            "learning_rate": hyperparameters.get("learning_rate", 0.1),
            "subsample": hyperparameters.get("subsample", 0.8),
            "colsample_bytree": hyperparameters.get("colsample_bytree", 0.8),
            "min_child_weight": hyperparameters.get("min_child_weight", 1),
            "gamma": hyperparameters.get("gamma", 0),
            "objective": "binary:logistic",
            "eval_metric": "auc",
            # Production settings
            "tree_method": "gpu_hist",  # GPU acceleration
            "gpu_id": 0,
            "predictor": "gpu_predictor",
        }
        
        num_rounds = hyperparameters.get("num_rounds", 200)
        
        evals = [(dtrain, "train"), (dval, "validation")]
        evals_result = {}
        
        self.model = xgb.train(
            params,
            dtrain,
            num_rounds,
            evals=evals,
            evals_result=evals_result,
            early_stopping_rounds=20,
            verbose_eval=10,
        )
        
        # Get feature importances
        self.feature_importance = self.model.get_score(importance_type="weight")
        
        # Evaluate
        val_preds = self.model.predict(dval)
        train_preds = self.model.predict(dtrain)
        
        metrics = self._calculate_metrics(y_train, train_preds, y_val, val_preds)
        
        print(f"\nTraining Results:")
        for metric, value in metrics.items():
            print(f"  {metric}: {value:.4f}")
        
        return metrics
    
    def _calculate_metrics(
        self,
        y_train: np.ndarray,
        train_preds: np.ndarray,
        y_val: np.ndarray,
        val_preds: np.ndarray,
    ) -> Dict[str, float]:
        """Calculate evaluation metrics."""
        metrics = {}
        
        # Train metrics
        train_auc = roc_auc_score(y_train, train_preds)
        metrics["train_auc"] = float(train_auc)
        
        # Validation metrics
        val_auc = roc_auc_score(y_val, val_preds)
        metrics["val_auc"] = float(val_auc)
        
        # Threshold = 0.5
        val_pred_binary = (val_preds > 0.5).astype(int)
        metrics["val_precision"] = float(precision_score(y_val, val_pred_binary))
        metrics["val_recall"] = float(recall_score(y_val, val_pred_binary))
        metrics["val_f1"] = float(f1_score(y_val, val_pred_binary))
        
        # Confusion matrix
        tn, fp, fn, tp = confusion_matrix(y_val, val_pred_binary).ravel()
        metrics["val_true_positives"] = float(tp)
        metrics["val_false_positives"] = float(fp)
        metrics["val_false_negatives"] = float(fn)
        metrics["val_true_negatives"] = float(tn)
        
        return metrics
    
    def predict(self, X: np.ndarray) -> np.ndarray:
        """Make predictions."""
        if self.model is None:
            raise ValueError("Model not trained yet")
        
        dtest = xgb.DMatrix(X)
        return self.model.predict(dtest)
    
    def save(self, model_path: str) -> None:
        """Save model."""
        os.makedirs(os.path.dirname(model_path), exist_ok=True)
        
        if self.model_type == "xgboost":
            self.model.save_model(model_path)
        
        print(f"Model saved to {model_path}")
    
    def load(self, model_path: str) -> None:
        """Load model."""
        if self.model_type == "xgboost":
            self.model = xgb.Booster(model_file=model_path)
        
        print(f"Model loaded from {model_path}")


class DataLoader:
    """Load and prepare data for training."""
    
    @staticmethod
    def load_csv(path: str) -> Tuple[np.ndarray, np.ndarray, list]:
        """Load CSV data and separate features/labels."""
        df = pd.read_csv(path)
        
        # Separate features and labels
        y = df["is_fraud"].values
        X = df.drop(columns=["is_fraud", "transaction_id"]).values
        feature_names = df.drop(columns=["is_fraud", "transaction_id"]).columns.tolist()
        
        print(f"Loaded {len(df)} samples with {len(feature_names)} features")
        print(f"Fraud rate: {y.sum() / len(y):.2%}")
        
        return X, y, feature_names
    
    @staticmethod
    def load_from_s3(bucket: str, key: str) -> Tuple[np.ndarray, np.ndarray, list]:
        """Load CSV from S3."""
        import boto3
        
        print(f"Loading from s3://{bucket}/{key}...")
        
        s3_client = boto3.client("s3")
        obj = s3_client.get_object(Bucket=bucket, Key=key)
        df = pd.read_csv(obj["Body"])
        
        return DataLoader.load_csv_from_df(df)
    
    @staticmethod
    def load_csv_from_df(df: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray, list]:
        """Load from dataframe."""
        y = df["is_fraud"].values
        X = df.drop(columns=["is_fraud", "transaction_id"]).values
        feature_names = df.drop(columns=["is_fraud", "transaction_id"]).columns.tolist()
        
        print(f"Loaded {len(df)} samples with {len(feature_names)} features")
        print(f"Fraud rate: {y.sum() / len(y):.2%}")
        
        return X, y, feature_names


def train_model(
    train_data_path: str,
    val_data_path: str,
    test_data_path: str,
    model_type: str = "xgboost",
    hyperparameters: Dict[str, Any] = None,
    output_path: str = "/opt/ml/model",
) -> None:
    """Complete training pipeline."""
    if hyperparameters is None:
        hyperparameters = {}
    
    print(f"Training {model_type} model...")
    
    # Load data
    X_train, y_train, feature_names = DataLoader.load_csv(train_data_path)
    X_val, y_val, _ = DataLoader.load_csv(val_data_path)
    X_test, y_test, _ = DataLoader.load_csv(test_data_path)
    
    # Initialize model
    model = FraudDetectionModel(model_type=model_type)
    
    # Train
    metrics = model.train(X_train, y_train, X_val, y_val, hyperparameters)
    
    # Evaluate on test set
    test_preds = model.predict(X_test)
    test_auc = roc_auc_score(y_test, test_preds)
    test_pred_binary = (test_preds > 0.5).astype(int)
    test_f1 = f1_score(y_test, test_pred_binary)
    
    print(f"\nTest Results:")
    print(f"  AUC: {test_auc:.4f}")
    print(f"  F1: {test_f1:.4f}")
    
    metrics["test_auc"] = float(test_auc)
    metrics["test_f1"] = float(test_f1)
    
    # Save model
    model_path = os.path.join(output_path, "model.bin")
    model.save(model_path)
    
    # Save metrics
    metrics_path = os.path.join(output_path, "metrics.json")
    os.makedirs(os.path.dirname(metrics_path), exist_ok=True)
    
    with open(metrics_path, "w") as f:
        json.dump(metrics, f, indent=2)
    
    print(f"\nMetrics saved to {metrics_path}")
    
    # Save feature names
    features_path = os.path.join(output_path, "features.json")
    with open(features_path, "w") as f:
        json.dump({"feature_names": feature_names}, f, indent=2)
    
    print(f"Features saved to {features_path}")


def main():
    parser = argparse.ArgumentParser(description="Train fraud detection model")
    parser.add_argument(
        "--train-data",
        type=str,
        required=True,
        help="Path to training data (CSV)",
    )
    parser.add_argument(
        "--val-data",
        type=str,
        required=True,
        help="Path to validation data (CSV)",
    )
    parser.add_argument(
        "--test-data",
        type=str,
        required=True,
        help="Path to test data (CSV)",
    )
    parser.add_argument(
        "--model-type",
        type=str,
        choices=["xgboost", "lightgbm"],
        default="xgboost",
        help="Model type to train",
    )
    parser.add_argument(
        "--max-depth",
        type=int,
        default=6,
        help="Max tree depth",
    )
    parser.add_argument(
        "--learning-rate",
        type=float,
        default=0.1,
        help="Learning rate",
    )
    parser.add_argument(
        "--num-rounds",
        type=int,
        default=200,
        help="Number of boosting rounds",
    )
    parser.add_argument(
        "--output-path",
        type=str,
        default="/opt/ml/model",
        help="Output path for model and metrics",
    )
    
    args = parser.parse_args()
    
    hyperparameters = {
        "max_depth": args.max_depth,
        "learning_rate": args.learning_rate,
        "num_rounds": args.num_rounds,
    }
    
    train_model(
        train_data_path=args.train_data,
        val_data_path=args.val_data,
        test_data_path=args.test_data,
        model_type=args.model_type,
        hyperparameters=hyperparameters,
        output_path=args.output_path,
    )


if __name__ == "__main__":
    main()
