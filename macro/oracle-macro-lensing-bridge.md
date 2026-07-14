# Oracle Macro Lensing Bridge

Status: research routing file
Created: 2026-06-18
Source side: `Composite Operator: Macro Lensing`
Target side: `Composite Operator Terminal` / Oracle validation harness

## Purpose

Macro Lensing entries produce useful market-structure insights, but they should not directly mutate Oracle, Pine, portfolio rules, or product language.

This file turns Macro Lensing into an Oracle-ready hypothesis feed:

```text
dated macro note -> extracted rule -> testable hypothesis -> Oracle experiment lane -> evidence packet -> critique -> routing verdict
```

Use this as an airlock. The Macro Lensing archive may supply claims and hypotheses. Oracle decides whether those claims survive data, controls, holdouts, nearby-date tests, and baseline comparison.

## Source Files

Primary source feed:

```text
research-rules.json
```

Human-readable rule index:

```text
research-rules.html
```

Post archive:

```text
posts/
```

## Boundary Rules

1. Treat Macro Lensing as a claim generator, not a signal authority.
2. Keep public-safe language separate from source/provenance language.
3. Freeze each dated rule before testing it against later data.
4. Do not rewrite older rules after seeing outcomes, except to correct file errors with a note.
5. Use only as-of data available at or before the thesis date.
6. Compare against Oracle v9.1 and against simple controls.
7. Require episode, holdout, nearby-control, and placebo survival before promotion.
8. A failed rule can still be useful if it explains false positives, false negatives, or regime-conditional behavior.

## Condensed Oracle-Ready Rule Families

These are the pared-down rule families distilled from the Macro Lensing research-rules archive and aligned to the Oracle testing method.

### ML-OR-001: Cross-Asset Agreement Beats Single-Index Pattern

Core rule:

```text
Risk posture should upgrade only when index price, breadth, volatility, dollar, rates, credit, and leadership stop disagreeing.
```

Oracle hypothesis:

```text
Cross-asset agreement should improve regime classification versus index-only price structures.
```

Feature lanes:

- index trend: SPY, QQQ, IWM, RSP
- breadth/participation: RSP/SPY, IWM/SPY, sector breadth proxies
- volatility: VIX, VIX term proxies when available
- dollar/FX: DXY or UUP, USDJPY, yen stress proxies
- rates/credit: TLT, yields, HYG/LQD, spreads where available
- leadership: XLK, SMH/SOXX, XLF, XLI, XLY, XLE, GDX/GDXJ

Oracle test route:

- relationship sweep
- strict family rescore
- Oracle marginal lift
- episode rescore
- episode holdout
- nearby-control episode gate
- chart-review quantifier

Failure modes:

- duplicate feature clusters masquerade as independent confirmation
- broad-market beta explains the effect
- signal only works in one era

### ML-OR-002: Dollar, Rates, And Policy Are Liquidity Gates

Core rule:

```text
Dollar strength, rate pressure, or a less-forgiving central bank reaction function should lower confidence in risk-on setups.
```

Oracle hypothesis:

```text
Risk-on features should degrade when dollar/rates/policy proxies are tightening, especially in high-beta, commodities, crypto, EM, and duration-heavy growth.
```

Feature lanes:

- DXY/UUP
- USDJPY and yen stress
- TLT and yield proxies
- SOFR, DFF, IORB, RRP, reserves, liquidity rails where available
- HYG/LQD or credit-spread proxies

Target labels:

- stress onset
- drawdown onset
- failed breakout / fake risk-on
- volatility expansion
- high-beta underperformance

Oracle test route:

- mechanism docket
- anchor polarity audit
- era-family holdout
- same-era placebo
- cross-target cluster placebo

Failure modes:

- dollar/rates are coincident rather than leading
- tightening proxies overfire in benign consolidations
- policy date alignment leaks future knowledge

### ML-OR-003: Volatility Is A Regime Switch, Not Background Noise

Core rule:

```text
Volatility shelves, failed VIX breakdowns, and high-teen VIX reclaims should change the acceptable risk posture.
```

Oracle hypothesis:

```text
Volatility threshold behavior should improve stress/drawdown classification and reduce false risk-on upgrades.
```

Feature lanes:

- VIX absolute level
- VIX reclaim/shelf behavior
- volatility of volatility if available
- SPY/QQQ realized volatility
- volatility divergence versus price support

Target labels:

- volatility expansion
- forced-selling regime
- failed support
- stress onset

Oracle test route:

- explicit regime gate test
- probability score / holdout
- suppression audit
- nearby-control chart review

Failure modes:

- VIX is too noisy without breadth and dollar filters
- threshold overfits one crisis period
- volatility spikes after damage, not before it

### ML-OR-004: Breadth And Leadership Quality Validate Risk-On

Core rule:

```text
Narrow leadership can support index price while masking fragile participation. Risk-on needs breadth expansion or leadership rotation quality.
```

Oracle hypothesis:

```text
Breadth/participation ratios should separate durable risk-on from narrow, late-cycle, or fake risk-on moves.
```

Feature lanes:

- RSP/SPY
- IWM/SPY
- equal-weight sector ratios
- QQQ/RSP, XLK/SPY, SMH/SPY
- cyclicals versus defensives
- financials, industrials, housing, discretionary

Target labels:

- regime transition
- failed rally
- leadership rotation
- forward return / drawdown

Oracle test route:

- family validation
- strict family rescore
- marginal lift where Oracle v9.1 is absent/disagrees/recently failed
- episode holdout
- sibling family controls

Failure modes:

- leadership ratio duplicates market beta
- breadth lags price in early recovery
- narrow leadership remains durable longer than expected

### ML-OR-005: Commodity Moves Need Regime Classification

Core rule:

```text
Commodity strength or weakness must be split into inflation impulse, growth/demand strength, demand destruction, and liquidity hedge.
```

Oracle hypothesis:

```text
Commodity features are context-dependent. Their predictive value improves when conditioned on dollar, rates, breadth, China/EM, and cyclicals.
```

Feature lanes:

- oil / USO / crude futures proxy
- copper / CPER / HG proxy
- gold / GLD
- silver / SLV
- gold-silver ratio
- miners: GDX, GDXJ, SIL, SILJ
- commodity basket proxies
- China/EM: FXI, EEM, KWEB where available

Target labels:

- inflation persistence
- demand destruction
- cyclical expansion
- commodity-led risk-on
- resource hedge rotation

Oracle test route:

- relationship sweep by target class
- conditional validation by regime
- era split
- mechanism control docket
- cross-target placebo

Failure modes:

- lower oil is misread as bullish when it is demand destruction
- gold strength is liquidity hedge, not broad risk-on
- miners amplify metal signals with equity-beta noise

### ML-OR-006: Support Zones Are Tests, Not Conclusions

Core rule:

```text
A support zone only gains authority after reaction, divergence, reclaim behavior, or clean corrective structure confirms it.
```

Oracle hypothesis:

```text
Support-zone proximity should not be scored as bullish unless paired with repair structure, volatility compression, breadth confirmation, or reduced liquidation pressure.
```

Feature lanes:

- drawdown distance from recent high
- distance to rolling support zones
- momentum divergence proxies
- reclaim behavior
- realized volatility compression
- breadth repair

Target labels:

- bottoming
- recovery
- failed support
- waterfall continuation
- chop/no-trade zone

Oracle test route:

- bottoming-trigger diagnostic
- recovery-entry decomposition
- pooled recovery-entry sensitivity
- bottoming-trigger control
- nearby-control episode gate

Failure modes:

- waiting for repair enters too late
- support levels become subjective
- straight-line liquidation through support invalidates the setup

### ML-OR-007: Headlines Need Second-Reaction Confirmation

Core rule:

```text
Headline-driven squeezes, policy events, and geopolitical pumps should be treated as liquidity information first. The second reaction matters more.
```

Oracle hypothesis:

```text
Event-window first moves should have lower predictive weight unless confirmed by cash-session follow-through, breadth, volatility, dollar, and rates.
```

Feature lanes:

- event-day return
- next-session follow-through
- overnight/cash divergence if available
- VIX response
- dollar/rates response
- breadth response

Target labels:

- headline whipsaw
- failed risk-on
- policy shock
- volatility expansion
- no-trade/chop

Oracle test route:

- event cluster lead/lag
- event cluster placebo
- offset sensitivity
- nonoverlap holdout
- false-positive / false-negative explainer

Failure modes:

- event calendar alignment leaks future context
- sample sizes are too small
- event effects are regime-specific and unstable

### ML-OR-008: Parabolic Leadership Needs Distribution/Reset Separation

Core rule:

```text
Parabolic or crowded leadership can reset constructively, but weak sideways failure near highs is distribution risk.
```

Oracle hypothesis:

```text
Overextended leadership should be split into healthy reset, distribution, and waterfall continuation using volatility, breadth, and reclaim behavior.
```

Feature lanes:

- SMH/SOXX, QQQ, XLK, mega-cap proxies
- distance from moving averages or recent highs
- realized volatility expansion
- breadth divergence
- ratio leadership versus SPY/RSP
- first support tag versus later reclaim

Target labels:

- leadership reset
- distribution
- waterfall continuation
- failed rally

Oracle test route:

- chart snapshot packet
- chart review docket
- chart-review quantifier
- anchor anatomy
- nearby controls

Failure modes:

- strong leaders remain overbought longer than tests expect
- first-support tags look predictive only in hindsight
- single-name leadership does not generalize to index regime

### ML-OR-009: Emerging Markets, China, Crypto, And High Beta Are Liquidity Beta

Core rule:

```text
EM, China, crypto, and high-beta assets should receive lower confidence when dollar/rates/volatility pressure rises together.
```

Oracle hypothesis:

```text
Liquidity-beta assets should amplify cross-asset tightening and provide early warning when they fail to confirm risk-on.
```

Feature lanes:

- EEM, FXI, KWEB
- BTC, ETH where available
- ARKK or high-beta proxies
- IWM, XBI, IPO/speculative proxies
- dollar and rates overlay

Target labels:

- liquidity stress
- speculative risk contraction
- high-beta underperformance
- crypto drawdown / recovery

Oracle test route:

- cross-target branch combiner
- cross-target cluster placebo
- relationship overlay packet
- marginal lift against Oracle v9.1

Failure modes:

- asset-specific news dominates macro signal
- crypto trades on separate liquidity rhythm
- EM/China data quality and symbol history constraints

### ML-OR-010: Credit-Sensitive Groups Deserve Extra Regime Weight

Core rule:

```text
Credit, financials, housing, small caps, and industrial cyclicals help distinguish ordinary rotation from liquidity stress.
```

Oracle hypothesis:

```text
Credit-sensitive and financing-sensitive groups should improve regime transition detection and reduce false bullish reads.
```

Feature lanes:

- HYG, LQD, HYG/LQD
- XLF, KRE if available
- XHB, ITB
- IWM/SPY
- XLI, XLY, XRT
- SOFR/Fed/liquidity rails

Target labels:

- credit-stress onset
- breadth deterioration
- failed rally
- drawdown onset

Oracle test route:

- relationship factory / scoring
- mechanism control docket
- anchor polarity era
- era-family holdout

Failure modes:

- financials lead for idiosyncratic earnings/regulation reasons
- housing rates sensitivity changes by era
- credit ETF prices are contaminated by duration effects

### ML-OR-011: No Middle Trade Without Visible Invalidation

Core rule:

```text
Unfinished corrective structures are not high-quality evidence. Wait for levels where stop, invalidation, or confirmation is visible.
```

Oracle hypothesis:

```text
Chop-zone / middle-structure labels should reduce false positives and improve no-trade classification.
```

Feature lanes:

- range position
- volatility compression/expansion
- false breakout frequency
- overlapping recent candles
- weak follow-through after trigger
- disagreement among price, breadth, volatility, and dollar

Target labels:

- no-trade / chop zone
- failed breakout
- whipsaw
- low-confidence regime

Oracle test route:

- no-trade label build
- false-positive explainer
- nearby controls
- baseline comparison

Failure modes:

- no-trade labels become too subjective
- reduced false positives also suppresses true positives
- labels depend on visual wave interpretation unless quantified

## Oracle Test Method Mapping

Use this test sequence before any Macro Lensing claim is allowed to influence Oracle design:

1. Extract the dated rule from `research-rules.json`.
2. Assign one or more `ML-OR-*` family IDs.
3. Convert the rule into a testable hypothesis with expected direction.
4. Map the hypothesis to target labels: forward return, drawdown, stress onset, volatility expansion, regime transition, fake risk-on, recovery, or no-trade.
5. Map features to known Oracle families and exact data catalog symbols.
6. Enforce as-of joins and no-lookahead alignment.
7. Run baseline comparison against frozen Oracle v9.1.
8. Run broad candidate discovery only if the feature meaning is explicit.
9. Run family validation and strict rescore.
10. Run Oracle marginal lift where v9.1 is absent, disagrees, or recently failed.
11. Compress events into episodes.
12. Run episode rescore and episode holdout.
13. Run nearby-control episode tests.
14. Run chart-review docket / quantifier for survivors.
15. Run control false-negative explainer and mechanism docket.
16. Run anchor polarity and era split.
17. Run era-family holdout and same-era placebo.
18. Route result as `archive_only`, `parking_lot`, `needs_control`, `needs_holdout`, `oracle_research_lane`, or `candidate_for_later_promotion`.

## Minimum Claim Object For Oracle

When Oracle mines Macro Lensing, convert each rule into this object shape before testing:

```json
{
  "source_id": "macro_lensing_YYYY-MM-DD",
  "source_file": "macro/posts/YYYY-MM-DD.html",
  "rule_family_id": "ML-OR-001",
  "claim_text": "Cross-asset agreement should outweigh a single index pattern.",
  "claim_type": "regime_filter",
  "capital_flow_channels": ["volatility", "dollar_fx", "rates_credit", "breadth", "leadership"],
  "expected_direction": "risk_on_confidence_falls_when_channels_disagree",
  "candidate_features": ["VIX", "UUP", "TLT", "HYG_LQD", "RSP_SPY", "IWM_SPY", "SMH_SPY"],
  "candidate_targets": ["drawdown_onset", "stress_onset", "failed_risk_on"],
  "test_route": ["strict_family_rescore", "oracle_marginal_lift", "episode_holdout", "nearby_control", "same_era_placebo"],
  "contamination_risk": "medium",
  "evidence_state": "unread",
  "routing_verdict": "needs_experiment"
}
```

## Promotion Bar

Do not promote a Macro Lensing rule into Oracle/Pine unless it survives at least:

- feature meaning definition
- data catalog check
- no-lookahead join audit
- baseline comparison
- family validation or strict rescore
- episode-level validation
- holdout/window split
- nearby-control test
- at least one adversarial control: placebo, sibling, shifted-date, false-negative explainer, or era split

Even after survival, the first promotion should usually be cockpit context or research warning, not a trade signal.

## Preferred Near-Term Experiments

1. Cross-asset disagreement as a risk-on suppression gate.
   - Families: `ML-OR-001`, `ML-OR-004`, `ML-OR-011`
   - Expected value: reduce false bullish reads.

2. Dollar/rates/volatility tightening as a high-beta confidence haircut.
   - Families: `ML-OR-002`, `ML-OR-003`, `ML-OR-009`
   - Expected value: improve stress/drawdown onset classification.

3. Commodity regime split.
   - Families: `ML-OR-005`, `ML-OR-010`
   - Expected value: distinguish inflation rotation from demand destruction.

4. Support-zone repair versus straight-line liquidation.
   - Families: `ML-OR-006`, `ML-OR-008`
   - Expected value: separate useful bottoming/recovery from falling-knife behavior.

5. Event/headline second-reaction filter.
   - Families: `ML-OR-007`, `ML-OR-011`
   - Expected value: reduce whipsaw false positives around policy/headline windows.

## Working Interpretation

Macro Lensing is most valuable to Oracle as a source of regime grammar:

- what channels should agree
- when a support zone is not enough
- when liquidity pressure should override a clean-looking chart
- when breadth and leadership should validate or veto price
- when commodity strength means inflation, growth, or stress
- when headline moves should be discounted until the second reaction

Oracle should mine this grammar, not imitate the voice. The archive becomes a dated hypothesis library; the harness decides which ideas earn statistical and structural respect.
