# GoldX – Architecture Overview

GoldX is a **trend-following scalping assistant** for XAUUSD (gold) built around three core layers:

1) **Signal Engine**
   - Ingests market data (1m → 1h candles).
   - Computes multi-timeframe trend context (M1, M5, M15, M30, H1).
   - Produces a directional signal: `long`, `short`, or `flat`, with a confidence score `0..1`.

2) **Risk Manager**
   - Transforms a raw signal into a trade plan using account equity, max risk %, ATR/volatility.
   - Outputs lot size, SL/TP distances, and optional break-even/partial close rules.

3) **Execution Adapter**
   - Sends the trade plan to the connected broker or platform.
   - Supports:
     - **HTTP/REST** (for custom bridges and prop firm APIs).
     - **MetaTrader 5 bridge** (sample connector in `examples/mt5-connector-sample.mq5`).

Auxiliary services:
- **State & Logging** – JSON logs + optional WebSocket stream.
- **Config** – YAML/JSON configuration with environment overrides.
- **Backtest Sandbox** – lightweight offline engine to replay candles and evaluate metrics.

---

## Data Flow (high level)

+-------------+ +---------------+ +--------------+ +----------------+
| Market Data | ---> | Signal Engine | ---> | Risk Manager | ---> | Exec. Adapter |
| (candles) | | MTF trend | | size/SL/TP | | (MT5 / REST) |
+-------------+ +---------------+ +--------------+ +----------------+
---

## Configuration

GoldX reads configuration from `config.json` (or environment variables):

```json
{
  "symbol": "XAUUSD",
  "timeframes": ["M1", "M5", "M15", "M30", "H1"],
  "risk": {
    "max_risk_pct": 0.5,
    "sl_atr_mult": 1.8,
    "tp_rr": 1.5
  },
  "execution": {
    "mode": "HTTP",
    "http_endpoint": "https://your-bridge.example.com/v1/orders",
    "api_key": "YOUR_API_KEY"
  }
}
Environment overrides (examples):GOLDX_SYMBOL=XAUUSD
GOLDX_MAX_RISK_PCT=0.5
GOLDX_EXECUTION_MODE=HTTP
GOLDX_HTTP_ENDPOINT=https://your-bridge.example.com/v1/orders
GOLDX_API_KEY=xxx
Components

goldx.signal

generate_signal(candles: dict) -> dict

Returns: {"side": "long|short|flat", "confidence": float, "context": {...}}

goldx.risk

make_trade_plan(signal: dict, account: dict, symbol_meta: dict) -> dict

Returns an executable order with lot size, SL/TP levels.

goldx.exec.http

place_order(plan: dict, api_key: str, endpoint: str) -> dict

goldx.exec.mt5

Examples provided in examples/mt5-connector-sample.mq5.
```
Notes

GoldX is an assistant: it produces structured, risk-aware trade plans to execute when the trend is clear.

All public pieces in this repository are released under the MIT License.

## License
MIT License for public components.

