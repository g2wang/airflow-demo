import os
import pandas as pd
import numpy as np

def generate_data():
    # Ensure data directory exists
    os.makedirs('data', exist_ok=True)
    
    # Seed for reproducibility
    np.random.seed(42)
    
    n_rows = 100
    
    # Options for categorization
    categories = ['Electronics', 'Clothing', 'Food', 'Books', 'Home']
    currencies = ['USD', 'EUR', 'GBP']
    
    data = {
        'transaction_id': [f'TXN{10000 + i}' for i in range(n_rows)],
        'user_id': [f'USR{np.random.randint(100, 150)}' for i in range(n_rows)],
        'timestamp': pd.date_range(start='2026-06-01', periods=n_rows, freq='3h'),
        'amount': np.round(np.random.uniform(-50.0, 600.0, n_rows), 2),  # contains some negative values
        'category': np.random.choice(categories, n_rows),
        'currency': np.random.choice(currencies, n_rows, p=[0.8, 0.15, 0.05])
    }
    
    df = pd.DataFrame(data)
    
    # Save as parquet using pyarrow
    parquet_path = 'data/transactions.parquet'
    df.to_parquet(parquet_path, index=False)
    print(f"Successfully generated {n_rows} transaction records in Parquet format at: {parquet_path}")

if __name__ == '__main__':
    generate_data()
