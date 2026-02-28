"""
Data preprocessing pipeline for fraud detection.
Handles feature engineering and data validation.
"""

import argparse
from abc import ABC, abstractmethod
from typing import Tuple, List, Optional

import boto3
import pandas as pd
import numpy as np
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.model_selection import train_test_split


class DataValidator(ABC):
    """Base class for data validation rules."""
    
    @abstractmethod
    def validate(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.Series]:
        """Validate and return cleaned dataframe and boolean mask."""
        pass


class RangeValidator(DataValidator):
    """Validate numeric features are within acceptable ranges."""
    
    def __init__(self, column: str, min_val: float = None, max_val: float = None):
        self.column = column
        self.min_val = min_val
        self.max_val = max_val
    
    def validate(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.Series]:
        mask = pd.Series([True] * len(df), index=df.index)
        
        if self.min_val is not None:
            mask &= df[self.column] >= self.min_val
        if self.max_val is not None:
            mask &= df[self.column] <= self.max_val
        
        return df[mask], mask


class MissingValueValidator(DataValidator):
    """Handle missing values."""
    
    def __init__(self, max_missing_ratio: float = 0.1):
        self.max_missing_ratio = max_missing_ratio
    
    def validate(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.Series]:
        missing_ratio = df.isnull().sum() / len(df)
        cols_to_drop = missing_ratio[missing_ratio > self.max_missing_ratio].index
        
        df_cleaned = df.drop(columns=cols_to_drop)
        df_cleaned = df_cleaned.dropna()
        
        mask = pd.Series([True] * len(df_cleaned), index=df_cleaned.index)
        return df_cleaned, mask


class DuplicateValidator(DataValidator):
    """Handle duplicate transactions."""
    
    def validate(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.Series]:
        # Keep first occurrence
        df_cleaned = df.drop_duplicates(subset=["transaction_id"], keep="first")
        
        mask = pd.Series([True] * len(df_cleaned), index=df_cleaned.index)
        return df_cleaned, mask


class OutlierDetector:
    """Detect and handle outliers using IQR method."""
    
    def __init__(self, columns: List[str], iqr_multiplier: float = 1.5):
        self.columns = columns
        self.iqr_multiplier = iqr_multiplier
        self.bounds = {}
    
    def fit(self, df: pd.DataFrame) -> None:
        """Calculate bounds from training data."""
        for col in self.columns:
            Q1 = df[col].quantile(0.25)
            Q3 = df[col].quantile(0.75)
            IQR = Q3 - Q1
            
            lower = Q1 - self.iqr_multiplier * IQR
            upper = Q3 + self.iqr_multiplier * IQR
            
            self.bounds[col] = (lower, upper)
    
    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        """Clip outliers to bounds."""
        df_clipped = df.copy()
        
        for col in self.columns:
            if col in self.bounds:
                lower, upper = self.bounds[col]
                df_clipped[col] = df_clipped[col].clip(lower, upper)
        
        return df_clipped


class FeatureEngineer:
    """Create derived features for better model performance."""
    
    @staticmethod
    def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
        """Create domain-specific features."""
        df = df.copy()
        
        # Time-based features
        df["timestamp"] = pd.to_datetime(df["timestamp"])
        df["hour"] = df["timestamp"].dt.hour
        df["day_of_week"] = df["timestamp"].dt.dayofweek
        df["day_of_month"] = df["timestamp"].dt.day
        df["is_night"] = ((df["hour"] >= 0) & (df["hour"] < 6)).astype(int)
        df["is_weekend"] = (df["day_of_week"] >= 5).astype(int)
        
        # Amount-based features
        df["log_amount"] = np.log1p(df["amount"])
        df["amount_squared"] = df["amount"] ** 2
        
        # Risk score features
        df["high_amount"] = (df["amount"] > df["amount"].quantile(0.75)).astype(int)
        df["unusual_time"] = df["is_night"].astype(int)
        
        # Device risk
        df["high_risk_device"] = (
            df["device_type"].isin(["unknown", "desktop"])
        ).astype(int)
        
        # Transaction type risk
        df["high_risk_transaction"] = (
            df["transaction_type"].isin(["card_not_present", "online"])
        ).astype(int)
        
        # Aggregate risk features
        df["total_risk_factors"] = (
            df["high_amount"]
            + df["unusual_time"]
            + df["high_risk_device"]
            + df["high_risk_transaction"]
        )
        
        return df
    
    @staticmethod
    def get_feature_list() -> List[str]:
        """Return list of engineered features."""
        return [
            "amount",
            "merchant_id",
            "country",
            "hour",
            "day_of_week",
            "day_of_month",
            "is_night",
            "is_weekend",
            "log_amount",
            "amount_squared",
            "high_amount",
            "unusual_time",
            "high_risk_device",
            "high_risk_transaction",
            "total_risk_factors",
        ]


class CategoricalEncoder:
    """Encode categorical features."""
    
    def __init__(self):
        self.encoders = {}
    
    def fit(self, df: pd.DataFrame, categorical_cols: List[str]) -> None:
        """Fit encoders on training data."""
        for col in categorical_cols:
            encoder = LabelEncoder()
            encoder.fit(df[col].astype(str))
            self.encoders[col] = encoder
    
    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        """Transform categorical columns."""
        df_encoded = df.copy()
        
        for col, encoder in self.encoders.items():
            df_encoded[col] = encoder.transform(df[col].astype(str))
        
        return df_encoded


class DataPreprocessor:
    """Complete data preprocessing pipeline."""
    
    def __init__(self):
        self.validators = []
        self.outlier_detector = OutlierDetector(
            columns=["amount", "merchant_id", "country"]
        )
        self.categorical_encoder = CategoricalEncoder()
        self.scaler = StandardScaler()
        self.feature_engineer = FeatureEngineer()
        self.feature_list = []
    
    def validate_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """Run all validation rules."""
        print("Validating data...")
        
        initial_count = len(df)
        
        # Check duplicates
        df = df.drop_duplicates(subset=["transaction_id"], keep="first")
        print(f"Duplicates removed: {initial_count - len(df)}")
        
        # Range validation
        df = df[(df["amount"] > 0) & (df["amount"] < 100000)]
        print(f"Invalid amounts removed: {initial_count - len(df)}")
        
        # Missing values
        df = df.dropna()
        print(f"Rows with missing values removed: {len(df)}")
        
        return df
    
    def preprocess(self, df: pd.DataFrame, fit: bool = False) -> Tuple[pd.DataFrame, List[str]]:
        """
        Complete preprocessing pipeline.
        
        Args:
            df: Input dataframe
            fit: If True, fit encoders/scalers. If False, use existing ones.
        
        Returns:
            Preprocessed dataframe and feature list
        """
        print("Starting preprocessing pipeline...")
        
        # 1. Validate data
        df = self.validate_data(df)
        
        # 2. Engineer features
        print("Engineering features...")
        df = self.feature_engineer.engineer_features(df)
        
        # 3. Detect and handle outliers
        print("Handling outliers...")
        if fit:
            self.outlier_detector.fit(df)
        df = self.outlier_detector.transform(df)
        
        # 4. Encode categorical features
        print("Encoding categorical features...")
        categorical_cols = ["device_type", "transaction_type"]
        
        if fit:
            self.categorical_encoder.fit(df, categorical_cols)
        df = self.categorical_encoder.transform(df)
        
        # 5. Select features
        self.feature_list = self.feature_engineer.get_feature_list()
        
        # 6. Drop unnecessary columns
        cols_to_keep = self.feature_list + ["transaction_id", "is_fraud"]
        df = df[[col for col in cols_to_keep if col in df.columns]]
        
        print(f"Final dataset shape: {df.shape}")
        print(f"Features: {self.feature_list}")
        
        return df, self.feature_list
    
    def scale_features(self, df: pd.DataFrame, fit: bool = False) -> pd.DataFrame:
        """Standardize numeric features."""
        df_scaled = df.copy()
        
        numeric_cols = df[self.feature_list].select_dtypes(
            include=[np.number]
        ).columns
        
        if fit:
            self.scaler.fit(df[numeric_cols])
        
        df_scaled[numeric_cols] = self.scaler.transform(df[numeric_cols])
        
        return df_scaled


def load_from_s3(s3_path: str) -> pd.DataFrame:
    """Load data from S3."""
    if not s3_path.startswith("s3://"):
        raise ValueError("S3 path must start with s3://")
    
    s3_path_parts = s3_path.replace("s3://", "").split("/", 1)
    bucket = s3_path_parts[0]
    key = s3_path_parts[1]
    
    print(f"Loading data from s3://{bucket}/{key}...")
    
    s3_client = boto3.client("s3")
    obj = s3_client.get_object(Bucket=bucket, Key=key)
    df = pd.read_csv(obj["Body"])
    
    print(f"Loaded {len(df)} rows")
    return df


def save_splits_to_s3(
    train_df: pd.DataFrame,
    val_df: pd.DataFrame,
    test_df: pd.DataFrame,
    bucket: str,
    prefix: str = "training-data",
) -> None:
    """Save train/val/test splits to S3."""
    s3_client = boto3.client("s3")
    
    datasets = {
        "train.csv": train_df,
        "validation.csv": val_df,
        "test.csv": test_df,
    }
    
    for filename, df in datasets.items():
        key = f"{prefix}/{filename}"
        csv_buffer = df.to_csv(index=False)
        
        s3_client.put_object(
            Bucket=bucket,
            Key=key,
            Body=csv_buffer,
            ContentType="text/csv",
        )
        
        print(f"Saved to s3://{bucket}/{key} ({len(df)} rows)")


def main():
    parser = argparse.ArgumentParser(description="Preprocess transaction data")
    parser.add_argument(
        "--input-path",
        type=str,
        required=True,
        help="Input data path (local or S3)",
    )
    parser.add_argument(
        "--output-path",
        type=str,
        required=True,
        help="Output data path",
    )
    parser.add_argument(
        "--train-val-test-split",
        type=str,
        default="0.7,0.15,0.15",
        help="Train/val/test split ratios (default: 0.7,0.15,0.15)",
    )
    parser.add_argument(
        "--s3-bucket",
        type=str,
        help="S3 bucket for output (if using S3)",
    )
    
    args = parser.parse_args()
    
    # Load data
    if args.input_path.startswith("s3://"):
        df = load_from_s3(args.input_path)
    else:
        df = pd.read_csv(args.input_path)
    
    print(f"Loaded {len(df)} rows")
    
    # Initialize preprocessor
    preprocessor = DataPreprocessor()
    
    # Preprocess
    df_processed, feature_list = preprocessor.preprocess(df, fit=True)
    
    # Scale features
    df_scaled = preprocessor.scale_features(df_processed, fit=True)
    
    # Split data
    splits = [float(x) for x in args.train_val_test_split.split(",")]
    train_ratio, val_ratio, test_ratio = splits
    
    # Train/test split
    train_df, test_df = train_test_split(
        df_scaled, test_size=(1 - train_ratio), random_state=42
    )
    
    # Val/test split
    val_ratio_adjusted = val_ratio / (val_ratio + test_ratio)
    val_df, test_df = train_test_split(
        test_df, test_size=val_ratio_adjusted, random_state=42
    )
    
    print(f"\nData splits:")
    print(f"Train: {len(train_df)} rows ({len(train_df)/len(df_scaled):.1%})")
    print(f"Validation: {len(val_df)} rows ({len(val_df)/len(df_scaled):.1%})")
    print(f"Test: {len(test_df)} rows ({len(test_df)/len(df_scaled):.1%})")
    
    print(f"\nFraud distribution:")
    for split_name, split_df in [
        ("Train", train_df),
        ("Val", val_df),
        ("Test", test_df),
    ]:
        fraud_rate = split_df["is_fraud"].mean()
        print(f"{split_name}: {fraud_rate:.2%}")
    
    # Save splits
    if args.s3_bucket:
        save_splits_to_s3(train_df, val_df, test_df, args.s3_bucket)
    else:
        train_df.to_csv(f"{args.output_path}/train.csv", index=False)
        val_df.to_csv(f"{args.output_path}/validation.csv", index=False)
        test_df.to_csv(f"{args.output_path}/test.csv", index=False)
        
        print(f"\nData splits saved to {args.output_path}/")


if __name__ == "__main__":
    main()
