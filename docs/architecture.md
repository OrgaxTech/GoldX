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

Notes

GoldX is an assistant: it produces structured, risk-aware trade plans to execute when the trend is clear.

All public pieces in this repository are released under the MIT License.
---

## `docs/api-reference.md`

```markdown
# GoldX API Reference

GoldX exposes both a **Python SDK surface** and **optional HTTP endpoints** for bridges.

---

## 1) Python SDK (public surface)

> The SDK examples below describe the public interface of the open parts. Internal logic can be replaced by users.

### `goldx.signal.generate_signal(candles) -> dict`

**Parameters**
- `candles` – dict of arrays keyed by timeframe (`"M1"`, `"M5"`, `"M15"`, `"M30"`, `"H1"`).  
  Each timeframe contains OHLCV arrays or a list of candle objects.

**Returns**
```json
{
  "side": "long|short|flat",
  "confidence": 0.72,
  "context": {
    "mtf_trend": {"M1":"up","M5":"up","M15":"up","M30":"up","H1":"flat"},
    "volatility": {"atr": 1.23}
  },
  "timestamp": 1730918400
}
goldx.risk.make_trade_plan(signal, account, symbol_meta) -> dict

Parameters

signal – the object returned by generate_signal.

account – { "equity": 10000, "currency": "USD" }

symbol_meta – { "pip_value": 0.01, "tick_size": 0.01, "atr": 1.2 }

Returns{
  "symbol": "XAUUSD",
  "side": "buy",
  "lots": 0.10,
  "sl": 2411.50,
  "tp": 2415.30,
  "rr": 1.5,
  "meta": {"risk_pct": 0.5}
}
goldx.exec.http.place_order(plan, api_key, endpoint) -> dict

Parameters

plan – order plan from make_trade_plan.

api_key – bearer token.

endpoint – e.g., https://your-bridge.example.com/v1/orders.

Returns{
  "status": "accepted",
  "order_id": "abc-123",
  "provider": "your-bridge"
}
2) HTTP/REST (for bridges)

Implemented by your bridge or adapter. GoldX calls it to execute.

Authentication

Authorization: Bearer <API_KEY>

POST /v1/orders – Place order

Request{
  "symbol": "XAUUSD",
  "side": "buy",
  "lots": 0.10,
  "sl": 2411.50,
  "tp": 2415.30,
  "client_tag": "goldx"
}
Response 201{
  "status": "accepted",
  "order_id": "abc-123",
  "price": 2412.00
}
Response 4xx
{ "error": "invalid_symbol", "message": "Symbol not allowed." }
POST /v1/cancel
Error Codes
Code	Meaning
invalid_symbol	The symbol isn’t tradable in bridge
bad_request	Payload missing/invalid fields
unauthorized	API key missing or invalid
rejected	Provider rejected the order
internal_error	Unexpected error in the bridge{ "order_id": "abc-123" }Rate Limits

Default: 30 requests/min per API key (configurable by the bridge).
---

## `docs/integration-guide.md`

```markdown
# GoldX Integration Guide

This guide helps you integrate GoldX in two ways:
1. **HTTP Bridge** (generic, recommended)
2. **MetaTrader 5 (MT5) Connector** (sample included)

---

## 1) Quick Start (HTTP Bridge)

1) Deploy or configure a small HTTP service that accepts:
   - `POST /v1/orders` to place an order
   - `POST /v1/cancel` to cancel

2) Configure environment:
export GOLDX_SYMBOL=XAUUSD
export GOLDX_EXECUTION_MODE=HTTP
export GOLDX_HTTP_ENDPOINT=https://your-bridge.example.com/v1/orders

export GOLDX_API_KEY=YOUR_API_KEY
3) In your app:
```python
from goldx.signal import generate_signal
from goldx.risk import make_trade_plan
from goldx.exec.http import place_order

candles = load_candles()  # Provide M1..H1 OHLCV
signal = generate_signal(candles)
if signal["side"] != "flat":
    account = {"equity": 10000, "currency": "USD"}
    symbol_meta = {"pip_value": 0.01, "tick_size": 0.01, "atr": 1.2}
    plan = make_trade_plan(signal, account, symbol_meta)
    result = place_order(plan, api_key=os.getenv("GOLDX_API_KEY"),
                         endpoint=os.getenv("GOLDX_HTTP_ENDPOINT"))
    print(result)
2) MetaTrader 5 Connector (sample)

See examples/mt5-connector-sample.mq5

It demonstrates how to:

Receive a JSON trade plan (via file/HTTP) and map to an MT5 order.

Validate symbol, lot size, SL/TP per broker contract size.

Send OrderSend() with appropriate MqlTradeRequest.

Mapping Notes

side: "buy" | "sell" → ORDER_TYPE_BUY | ORDER_TYPE_SELL

lots → volume

sl/tp in price terms; ensure proper normalization with SymbolInfoDouble(_Symbol, SYMBOL_POINT).3) Symbols & Timeframes

GoldX is tuned for XAUUSD.

Timeframes used by default: M1, M5, M15, M30, H1.

You can override them in config.json or env variables, but consistency across feeds is critical.4) Deployment Tips

Logs: persist JSON logs for audits.

Latency: place the bridge near your broker’s server if possible.

API keys: treat as secrets; rotate periodically.

Dry-run: develop with a paper/demo account first.5) Troubleshooting
Symptom	Likely Cause	Fix
Orders rejected	Broker symbol or lot rules	Normalize size, check min/max lot
SL/TP “off quotes”	Price precision / distance too tight	Apply SymbolInfoDouble and min distance
“flat” signals too often	No clear MTF alignment	Wait for trend alignment or widen filters
HTTP 401	Missing/invalid API key	Set GOLDX_API_KEY properly
---

## Optional: `README.md` (top level)

```markdown
# GoldX

Official public SDK structure for OrgaX’s GoldX trading assistant (XAUUSD).  
This repository includes **docs**, **examples**, and the **public API surface**.

## Key Features
- Multi-timeframe trend detection (M1 → H1)
- Volatility-adaptive scalping logic
- Risk-controlled execution (lot sizing, SL/TP)

## Repository Structure
GoldX/
├─ docs/
│ ├─ architecture.md
│ ├─ api-reference.md
│ └─ integration-guide.md
├─ examples/
│ ├─ python-example.py
│ └─ mt5-connector-sample.mq5
├─ LICENSE
└─ README.md
## Documentation
All documentation lives in `docs/`. Start with `docs/integration-guide.md`.

## License
MIT License for public components.

