# GoldX — Integration Guide

This guide shows how to run GoldX with the **MT5 bridge** (recommended) or a **Python-only adapter**.

---

## 1. Prerequisites

- Python 3.10+  
- MetaTrader 5 terminal (for live/paper via MT5)  
- A Windows session (MT5) or a broker REST account if using a REST adapter  
- Clone this repo

git clone https://github.com/OrgaxTech/GoldX.git
cd GoldX
Folder structure is documented in README.md and docs/architecture.md.

## 2. Configure
Create config/goldx.json:
```json
{
  "symbol": "XAUUSD",
  "timeframes": ["M1","M5","M15","M30","H1"],
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
  "telemetry": {"log_level": "info"}
}
```
## 3. MT5 Integration (Bridge)

1. Open MetaEditor → create an Expert Advisor and paste the sample from
examples/mt5-connector-sample.mq5 (or just copy that file into MQL5/Experts/).

2. In the EA parameters:

Set Symbol = XAUUSD

Set the magic to match config.execution.magic

Allow algorithmic trading and DLL if needed by your environment

Attach the EA to an XAUUSD chart (preferably M1). It will relay ticks/bars and execute orders from GoldX.

3. EA responsibilities

Send ticks/bars to GoldX (IPC/Socket/Files depending on your variant)

Receive orders and call OrderSend / PositionClose

Report execution back

## 4. Python Runner
Minimal example (see examples/python-example.py for a complete one):
```python
import json
from goldx import GoldXClient, TrendEngine, RiskManager
from goldx.adapters import MT5Adapter
from goldx.data import mt5_tick_stream  # hypothetical helper

cfg = json.load(open("config/goldx.json", "r"))

client = GoldXClient(cfg)
client.set_trend_engine(TrendEngine(cfg["timeframes"]))
client.set_risk_manager(RiskManager(account={}, params=cfg["risk"]))
client.set_execution_adapter(MT5Adapter(cfg["execution"]))

client.start()
try:
    for tick in mt5_tick_stream(cfg["symbol"]):
        client.on_tick(tick)
finally:
    client.stop()
```
## 5. REST Adapter (Optional)

If your broker exposes REST endpoints, implement ExecutionAdapter and point
execution.adapter to "rest". See docs/architecture.md for the required methods.

## 6. Backtest Workflow (Quick)

Export historical bars (CSV/Parquet)

Feed them to a replay loop:
```python
for bar in read_csv_bars("data/XAUUSD_M1.csv"):
    client.on_bar(bar)
```
Collect PnL/metrics to validate settings.

## 7. Troubleshooting
No orders? Check EA journal (MT5) and Python logs.
Wrong symbol or digits? Make sure broker symbol settings match configuration.
Latency issues? Reduce logging level (telemetry.log_level = "warn").

## 8. FAQ
Is GoldX fully automated?
GoldX acts as a precision assistant; it shines when the market trend is clear. You stay in control.

Which markets are supported?
Primary: XAUUSD. Optional: BTCUSD (via custom adapter).

Can I replace the trend logic?
Yes—inject your own TrendEngine implementation.


---

### That’s it

Paste each block into the matching file and commit. Your repo will now look legit with:
- a clear architecture doc,
- a usable API reference,
- and a step-by-step integration guide.

If you want, I can also generate a tight `README.md` that links to these docs and shows the badges/quick start.
::contentReference[oaicite:0]{index=0}

