# GoldX — API Reference

This document describes the **public Python SDK surface** and the **execution adapter contract** used by GoldX.  
If you use the MT5 bridge, see `examples/mt5-connector-sample.mq5` for the MQL5 side.

> Namespace examples assume `from goldx import GoldXClient, RiskManager, TrendEngine`.

---

## 1.Core Classes

### `GoldXClient`

```python
class GoldXClient:
    def __init__(self, config: dict): ...
    def start(self) -> None: ...
    def stop(self) -> None: ...
    def on_tick(self, tick: dict) -> None: ...
    def on_bar(self, bar: dict) -> None: ...
    def set_execution_adapter(self, adapter) -> None: ...
    def set_risk_manager(self, rm) -> None: ...
    def set_trend_engine(self, te) -> None: ...
Notes

tick shape: {"symbol": "XAUUSD", "bid": 2373.10, "ask": 2373.30, "time": 1731009600}

bar shape: {"tf": "M1", "o": 2372.5, "h": 2373.9, "l": 2371.8, "c": 2373.1, "time": 1731009600}
```
Notes

```python
tick shape: {"symbol": "XAUUSD", "bid": 2373.10, "ask": 2373.30, "time": 1731009600}
```
```python
bar shape: {"tf": "M1", "o": 2372.5, "h": 2373.9, "l": 2371.8, "c": 2373.1, "time": 1731009600}
```
TrendEngine:
```python
class TrendEngine:
    def __init__(self, timeframes: list[str]): ...
    def update(self, bar: dict) -> None: ...
    def direction(self) -> tuple[str, float]:
        """Return ('bullish'|'bearish'|'neutral', confidence 0..1)"""
```
RiskManager:
```python
class RiskManager:
    def __init__(self, account: dict, params: dict): ...
    def compute_order(self, signal: dict) -> dict:
        """
        signal: {'symbol': 'XAUUSD', 'side': 'buy'|'sell', 'confidence': 0..1, 'price': float}
        return: order request => {'symbol','type','side','volume','price','sl','tp','comment','tags':[]}
        """
    def on_fill(self, execution_report: dict) -> None: ...
```
ExecutionAdapter (interface):
```python
class ExecutionAdapter:
    def connect(self) -> None: ...
    def send_order(self, request: dict) -> dict: ...
    def modify_order(self, order_id: str, fields: dict) -> dict: ...
    def close_position(self, position_id: str) -> dict: ...
    def account_info(self) -> dict: ...
```
Typical Run:
```python
from goldx import GoldXClient, TrendEngine, RiskManager
from goldx.adapters import MT5Adapter
from goldx.data import make_tick_stream  # hypothetical helper

cfg = load_json("config/goldx.json")

client = GoldXClient(cfg)
client.set_trend_engine(TrendEngine(cfg["timeframes"]))
client.set_risk_manager(RiskManager(account={}, params=cfg["risk"]))
client.set_execution_adapter(MT5Adapter(cfg["execution"]))

client.start()
for tick in make_tick_stream(symbol=cfg["symbol"]):
    client.on_tick(tick)
client.stop()
```
## 2. Order Request Schema
```json
{
  "symbol": "XAUUSD",
  "type": "market",              // or 'limit', 'stop'
  "side": "buy",                 // 'buy' | 'sell'
  "volume": 0.10,                // lots
  "price": 2373.10,              // for limit/stop, optional for market
  "sl": 2370.60,
  "tp": 2375.30,
  "comment": "goldx:v1",
  "tags": ["trend=M15", "rr=1.8"]
}
```
Execution report (example):
```json
{
  "ok": true,
  "order_id": "MT5#1234567",
  "position_id": "MT5#7654321",
  "price_fill": 2373.12,
  "message": "Filled",
  "ts": 1731009605
}
```
## 3. Errors
```bash
AdapterConnectionError
```

```bash
OrderRejectedError
```

```bash
InvalidConfigError
```

All raise with a clear .message and are also logged by Telemetry.

## 4.Utilities
```bash
goldx.utils.atri(bars, period=14) -> float
```
```bash
goldx.utils.position_size(account_balance, risk, stop_points, tick_value) -> float
```
```bash
goldx.utils.timestamp()
```


