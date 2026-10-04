# Compulsory Assignment 1 review guide

<span style="color: #666666;"><strong>Dansk: Vejledning til gennemgang af obligatorisk opgave 1</strong></span>

**Repository:** [github.com/hplaursen/mobilityticketing](https://github.com/hplaursen/mobilityticketing). Confirm that the lecturer and review group can access it.

<span style="color: #666666;"><strong>Dansk:</strong> [GitHub-repository](https://github.com/hplaursen/mobilityticketing). Kontrollér, at underviseren og reviewgruppen har adgang.</span>

**Submitted commit:** Provide the exact commit hash in the Moodle submission form.

<span style="color: #666666;"><strong>Dansk:</strong> Angiv den præcise commit-hash i Moodle-afleveringen.</span>

**Setup and reset:** Use the relevant [Lecture 1](lecture-1/README.md), [Lecture 2](lecture-2/README.md), [Lecture 3](lecture-3/README.md) or [Lecture 4](lecture-4/README.md) README. Run commands from that folder. Lectures 1, 2 and 4 use port 5432; Lecture 3 uses 55432. Stop any existing service or Swarm stack using the same port first. Use `docker compose down -v` then `docker compose up -d` for a clean seed.

<span style="color: #666666;"><strong>Dansk:</strong> Brug den relevante README til [Lecture 1](lecture-1/README.md), [Lecture 2](lecture-2/README.md), [Lecture 3](lecture-3/README.md) eller [Lecture 4](lecture-4/README.md). Kør kommandoerne fra den mappe. Lecture 1, 2 og 4 bruger port 5432; Lecture 3 bruger port 55432. Stop først andre services eller Swarm-stacks, der bruger samme port. Brug `docker compose down -v` og derefter `docker compose up -d` for en ren seed.</span>

## Where to find the work

<span style="color: #666666;"><strong>Dansk: Her finder du arbejdet</strong></span>

- **Lecture 1 — workload map, model, schema, seed and queries:** [workload map and assumption](lecture-1/docs/lab.md), [ER diagram](lecture-1/database/postgres/er-diagram.md), [schema](lecture-1/database/postgres/001_relational_baseline.sql), [seed data](lecture-1/database/postgres/002_seed.sql), and [three route/timetable queries](lecture-1/database/postgres/003_workload_queries.sql).

  <span style="color: #666666;"><strong>Dansk:</strong> **Lecture 1 — workload map, model, skema, seed-data og forespørgsler:** [workload map og antagelse](lecture-1/docs/lab.md), [ER-diagram](lecture-1/database/postgres/er-diagram.md), [skema](lecture-1/database/postgres/001_relational_baseline.sql), [seed-data](lecture-1/database/postgres/002_seed.sql) og [de tre rute- og køreplansforespørgsler](lecture-1/database/postgres/003_workload_queries.sql).</span>

- **Lecture 2 — integrity map, migration and tests:** [integrity map](lecture-2/docs/integrity-map-template.md), [constraint migration](lecture-2/database/postgres/migrations/011_ticketing_integrity.sql), [valid writes](lecture-2/database/postgres/experiments/constraints_should_succeed.sql), [rejected writes](lecture-2/database/postgres/experiments/constraints_should_fail.sql), and [observed results](lecture-2/docs/evidence/lecture02/README.md).

  <span style="color: #666666;"><strong>Dansk:</strong> **Lecture 2 — integritetsoversigt, migration og tests:** [integritetsoversigt](lecture-2/docs/integrity-map-template.md), [constraint-migration](lecture-2/database/postgres/migrations/011_ticketing_integrity.sql), [gyldige writes](lecture-2/database/postgres/experiments/constraints_should_succeed.sql), [afviste writes](lecture-2/database/postgres/experiments/constraints_should_fail.sql) og [registrerede resultater](lecture-2/docs/evidence/lecture02/README.md).</span>

- **Lecture 3 — reporting query, function, trigger and materialized view:** [base-table query](lecture-3/database/postgres/queries/base_revenue.sql), [function](lecture-3/database/postgres/migrations/020_reporting_function.sql), [trigger summary](lecture-3/database/postgres/migrations/021_daily_revenue_trigger.sql), [materialized view](lecture-3/database/postgres/migrations/022_daily_captured_revenue.sql), [test cases](lecture-3/database/postgres/experiments/reporting_cases.sql), [responsibility decision](lecture-3/docs/lab-answers.md), and [comparison evidence](lecture-3/docs/evidence/lecture03/README.md).

  <span style="color: #666666;"><strong>Dansk:</strong> **Lecture 3 — rapporteringsforespørgsel, funktion, trigger og materialiseret view:** [forespørgsel på basistabeller](lecture-3/database/postgres/queries/base_revenue.sql), [funktion](lecture-3/database/postgres/migrations/020_reporting_function.sql), [triggeropsummering](lecture-3/database/postgres/migrations/021_daily_revenue_trigger.sql), [materialiseret view](lecture-3/database/postgres/migrations/022_daily_captured_revenue.sql), [testscenarier](lecture-3/database/postgres/experiments/reporting_cases.sql), [beslutningen om rapporteringsansvar](lecture-3/docs/lab-answers.md) og [sammenligningsresultater](lecture-3/docs/evidence/lecture03/README.md).</span>

- **Lecture 4 — migration stages and verification:** [Moodle answers](lecture-4/docs/moodle-answers.md), [expand/backfill/contract migrations](lecture-4/database/postgres/migrations/), [old/new reader and writer tests](lecture-4/database/postgres/experiments/lecture04/), and [run evidence with ticket-price checks](lecture-4/docs/evidence/lecture04/README.md).

  <span style="color: #666666;"><strong>Dansk:</strong> **Lecture 4 — migrationstrin og verifikation:** [Moodle-besvarelse](lecture-4/docs/moodle-answers.md), [migrationer for udvidelse, backfill og kontraktion](lecture-4/database/postgres/migrations/), [tests af gamle og nye læsere og skrivere](lecture-4/database/postgres/experiments/lecture04/) samt [kørselsresultater med kontrol af billetpriser](lecture-4/docs/evidence/lecture04/README.md).</span>

## Two decisions worth discussing

<span style="color: #666666;"><strong>Dansk: To beslutninger, der er værd at drøfte</strong></span>

1. **Identify a route-stop position by `(route_id, stop_sequence)`.** The alternative `(route_id, stop_id)` would prevent a route from visiting the same stop twice. The sequence key fits loop routes and lets the ordered-stop query represent each visit. Evidence: [ER diagram and assumption](lecture-1/database/postgres/er-diagram.md) and [schema](lecture-1/database/postgres/001_relational_baseline.sql).

   <span style="color: #666666;"><strong>Dansk:</strong> **Identificér et stoppested på ruten med `(route_id, stop_sequence)`.** Alternativet `(route_id, stop_id)` ville forhindre, at en rute besøger samme stoppested flere gange. Sekvensnøglen passer til ringruter og gør det muligt for forespørgslen at vise hvert besøg i rækkefølge. Se [ER-diagram og antagelse](lecture-1/database/postgres/er-diagram.md) og [skema](lecture-1/database/postgres/001_relational_baseline.sql).</span>

2. **Put the current revenue calculation in a SQL function over `payments`.** A materialized view or trigger summary can reduce repeated aggregation, but each stored copy needs refresh, correction and rebuild rules. The function reflects payment corrections directly and fits this workload because no measurement shows that report reads need stored totals. Evidence: [four-way results and recommendation](lecture-3/docs/evidence/lecture03/README.md).

   <span style="color: #666666;"><strong>Dansk:</strong> **Placér den aktuelle indtægtsberegning i en SQL-funktion over `payments`.** Et materialiseret view eller en triggeropsummering kan mindske gentagne beregninger, men kræver regler for opdatering, rettelser og genopbygning. Funktionen afspejler betalingsrettelser direkte, og der er ingen målinger, som viser behov for gemte totaler. Se [sammenligning og anbefaling](lecture-3/docs/evidence/lecture03/README.md).</span>

## One limitation or open question

<span style="color: #666666;"><strong>Dansk: En begrænsning eller et åbent spørgsmål</strong></span>

The Lecture 2 capacity check prevents one trip row from exceeding capacity, but it does not coordinate simultaneous purchases competing for the final seat. The evidence contains valid and rejected writes, not a concurrent booking test. Next, run two purchases for one remaining seat and document the transaction or locking strategy. See the [integrity map](lecture-2/docs/integrity-map-template.md) and [Lecture 2 evidence](lecture-2/docs/evidence/lecture02/README.md).

<span style="color: #666666;"><strong>Dansk:</strong> Kapacitetskontrollen i Lecture 2 forhindrer, at én trip-række overstiger sin kapacitet, men den koordinerer ikke samtidige køb af den sidste plads. Dokumentationen viser gyldige og afviste writes, men ikke en test af samtidige køb. Næste skridt er at teste to køb af én ledig plads og dokumentere transaktions- eller låsestrategien. Se [integritetsoversigten](lecture-2/docs/integrity-map-template.md) og [evidens fra Lecture 2](lecture-2/docs/evidence/lecture02/README.md).</span>
