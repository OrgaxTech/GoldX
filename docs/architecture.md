# GoldX — Architecture

GoldX is a lightweight trading assistant/SDK designed for **clear-trend execution** on **XAUUSD** (primary) and **BTCUSD** (optional).  
It focuses on three things: **trend detection across M1→H1**, **risk-controlled order sizing**, and **adapter-based execution**.

---

## High-Level Components
+-----------------+ +------------------+ +---------------------+
| Data Feeds | -----> | Signal Engine | -----> | Risk Manager |
| (Broker API, | | (Multi-TF trend) | | (size, SL/TP, DD) |
| MT5 bridge) | +---------+--------+ +----------+----------+
| | | |
+-----------------+ v v
+---------------------+ +--------------------+
| Execution Adapter | --> | Broker/Exchange |
| (MT5, REST, FIX) | | (orders, account) |
+----------+----------+ +--------------------+
|
v
+---------------+
| Telemetry |
| (logs, metrics|
| and events) |
+---------------+

**Modules**
- **Signal Engine**  
  Computes directional bias using multi-timeframe inputs (M1, M5, M15, M30, H1).  
  Outputs: `bullish`, `bearish`, `neutral` with a confidence score `0..1`.

- **Risk Manager**  
  Converts intent into executable orders: position size, stop, take-profit, break-even, pause after profit, etc.

- **Execution Adapter**  
  Pluggable layer (MT5 Expert/Bridge, REST, or custom) that actually places/updates/cancels orders.

- **Telemetry**  
  Structured logs + optional metrics stream for later review or backtesting notes.

---

## Data Flow

1. **Tick/Bar arrives** → routed to the **Signal Engine**.  
2. **Signal Engine** produces `{direction, confidence, trend_tf_snapshot}`.  
3. **Risk Manager** computes `{volume, sl, tp, tags}`.  
4. **Execution Adapter** sends the order and watches its lifecycle.  
5. **Telemetry** records every decision + broker response.

---

## Configuration (example)

You can keep configuration in `config/goldx.json`:

```json
{
  "symbol": "XAUUSD",
  "timeframes": ["M1", "M5", "M15", "M30", "H1"],
  "risk": {
    "max_risk_per_trade": 0.01,
    "stop_atr_mult": 2.5,
    "tp_rr": 1.8
  },
  "execution": {
    "adapter": "mt5",
    "magic": 20251107,
    "slippage_points": 10
  },
  "telemetry": {
    "log_level": "info"
  }
}
```
Threading Model

Signal evaluation runs on the market data loop.

Execution is async, responses are queued back to the main loop.

Telemetry is non-blocking (fire-and-forget).

Create a class that implements:
```json
class ExecutionAdapter:
    def connect(self) -> None: ...
    def send_order(self, request: dict) -> dict: ...
    def modify_order(self, order_id: str, fields: dict) -> dict: ...
    def close_position(self, position_id: str) -> dict: ...
    def account_info(self) -> dict: ...
```
Register it in execution.adapter (e.g., rest, mt5, paper).
```bash
/docs
  ├─ architecture.md
  ├─ api-reference.md
  └─ integration-guide.md
/examples
  ├─ python-example.py            # minimal Python run-loop example
  └─ mt5-connector-sample.mq5     # MT5 bridge (sample)
LICENSE
README.md
```

