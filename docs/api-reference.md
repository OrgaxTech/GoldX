```markdown
# GoldX — API Reference

This document describes the **public Python SDK surface** and the **execution adapter contract** used by GoldX.  
If you use the MT5 bridge, see `examples/mt5-connector-sample.mq5` for the MQL5 side.

> Namespace examples assume `from goldx import GoldXClient, RiskManager, TrendEngine`.

---

## 1. Core Classes

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
