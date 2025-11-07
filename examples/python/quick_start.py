# examples/python/quick_start.py

def fetch_data():
    return [2400.0, 2400.5, 2401.2, 2399.8]

def simple_signal(data):
    sma = sum(data[-3:]) / 3
    return "BUY" if data[-1] > sma else "SELL"

if __name__ == "__main__":
    prices = fetch_data()
    print("Signal:", simple_signal(prices))
