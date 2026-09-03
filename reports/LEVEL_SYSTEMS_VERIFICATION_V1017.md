# Level Systems Verification (1.0.17, generator_version 2)

Output of `scripts/dev/verify_level_systems.gd`, which renders the real generated data for the four level systems so their behaviour can be inspected rather than taken on trust.

```

================ 2. LEVEL-TEMPLATE SYSTEM ================
Each template is a whole composition. The point is that the levers
move INDEPENDENTLY - a hard queue can pair with short targets, and a
kind queue with a long climb. If they all moved together this would
just be the old single difficulty ladder wearing 18 names.

template           band        queue     layout             rows  targets        limited
chain_friendly     NORMAL      balanced  chain_opportunity  3     climb_base     no
dense_opening      NORMAL      balanced  dense_top          4     top_pair       no
expert             EXPERT      scarce    split_clusters     4     climb_heavy    no
expert_volume      EXPERT      lean      wide_center_gap    4     climb_wide     no
high_pressure      HARD        scarce    center_heavy       4     climb_base     no
high_tier_build    HARD        balanced  split_clusters     3     climb_middle   no
limited_dense      CHALLENGING generous  dense_top          4     pair_low       yes m=1.60
limited_expert     EXPERT      lean      center_heavy       4     climb_single   yes m=1.30
limited_generous   NORMAL      generous  right_heavy        2     pair_low       yes m=1.70
limited_standard   CHALLENGING balanced  alternating_gaps   3     base_pair      yes m=1.45
limited_tight      HARD        lean      wide_center_gap    3     base_heavy     yes m=1.32
low_tier_build     CHALLENGING lean      alternating_gaps   3     low_build      no
precision          CHALLENGING lean      two_pocket         3     climb_single   no
recovery           EASY        generous  left_heavy         2     base_pair      no
relaxed            EASY        generous  sparse_top         2     climb_single   no
target_heavy       CHALLENGING generous  sparse_top         2     climb_wide     no
tutorial_open      TUTORIAL    intro     empty              0     climb_single   no
tutorial_seeded    TUTORIAL    intro     staggered_gaps     2     climb_single   no

Independence check - same queue band, different target structures:
  queue balanced  -> 4 distinct target structures: base_pair, climb_base, climb_middle, top_pair
  queue scarce    -> 2 distinct target structures: climb_base, climb_heavy
  queue lean      -> 4 distinct target structures: base_heavy, climb_single, climb_wide, low_build
  queue generous  -> 4 distinct target structures: base_pair, climb_single, climb_wide, pair_low
  queue intro     -> 1 distinct target structures: climb_single

================ 3. TARGET PROGRESSION ================
Old behaviour: every late normal level was L6x3 -> L7x2 -> L8x1 and
every limited level was L6x1 -> L7x1. Below is what levels 30-55
actually ask for now.

  L30  normal    precision          L6x1 -> L7x1 -> L8x1
  L31  limited   limited_tight      L6x3 -> L7x1
  L32  normal    recovery           L6x2 -> L7x1
  L33  normal    high_tier_build    L6x1 -> L7x2 -> L8x1
  L34  normal    expert_volume      L6x3 -> L7x2 -> L8x1
  L35  normal    chain_friendly     L6x2 -> L7x1 -> L8x1
  L36  limited   limited_dense      L6x1 -> L7x1
  L37  normal    expert_volume      L6x3 -> L7x2 -> L8x1
  L38  normal    precision          L6x1 -> L7x1 -> L8x1
  L39  limited   limited_tight      L6x3 -> L7x1
  L40  normal    dense_opening      L7x1 -> L8x1
  L41  limited   limited_tight      L6x3 -> L7x1
  L42  normal    expert             L6x2 -> L7x2 -> L8x1
  L43  normal    low_tier_build     L6x2 -> L7x2
  L44  normal    high_pressure      L6x2 -> L7x1 -> L8x1
  L45  limited   limited_tight      L6x3 -> L7x1
  L46  normal    expert             L6x2 -> L7x2 -> L8x1
  L47  normal    high_tier_build    L6x1 -> L7x2 -> L8x1
  L48  limited   limited_standard   L6x2 -> L7x1
  L49  normal    expert_volume      L6x3 -> L7x2 -> L8x1
  L50  normal    expert             L6x2 -> L7x2 -> L8x1
  L51  normal    low_tier_build     L6x2 -> L7x2
  L52  limited   limited_standard   L6x2 -> L7x1
  L53  normal    expert_volume      L6x3 -> L7x2 -> L8x1
  L54  limited   limited_expert     L6x1 -> L7x1 -> L8x1
  L55  normal    target_heavy       L6x3 -> L7x2 -> L8x1

Distinct target ladders in that 26-level window: 10
  L6x1 -> L7x1           x1
  L6x1 -> L7x1 -> L8x1   x3
  L6x1 -> L7x2 -> L8x1   x2
  L6x2 -> L7x1           x3
  L6x2 -> L7x1 -> L8x1   x2
  L6x2 -> L7x2           x2
  L6x2 -> L7x2 -> L8x1   x3
  L6x3 -> L7x1           x4
  L6x3 -> L7x2 -> L8x1   x5
  L7x1 -> L8x1           x1

Ascending-tier rule across levels 1-120 (a gem merged above the
active card is never banked for a later one, so a descending ladder
would strand work the player must do anyway):
  violations: 0

================ 4. LAYOUT VARIATION ================
Every archetype rendered from its real generated placements. '#' is a
seeded gem, '.' an opening. Row 0 is the LOWEST row (nearest the
danger line); higher rows sit further above it.

  staggered_gaps (14 gems)
    row 3  .#.#.#...
    row 2  ..#.#.#.#
    row 1  .#...#.#.
    row 0  #.#.#.#..

  left_heavy (14 gems)
    row 3  .#.#...#.
    row 2  #.#.#.#..
    row 1  .#.#...#.
    row 0  #.#.#.#..

  right_heavy (14 gems)
    row 3  .#...#.#.
    row 2  ..#.#.#.#
    row 1  .#...#.#.
    row 0  ..#.#.#.#

  center_heavy (14 gems)
    row 3  ...#.#.#.
    row 2  #.#.#.#..
    row 1  ...#.#.#.
    row 0  #.#.#.#..

  split_clusters (14 gems)
    row 3  .#.#.#...
    row 2  #.#...#.#
    row 1  .#.#.#...
    row 0  #.#...#.#

  alternating_gaps (14 gems)
    row 3  .#.#.#...
    row 2  ..#.#.#.#
    row 1  .#.#.#...
    row 0  ..#.#.#.#

  wide_center_gap (12 gems)
    row 3  ...#.#.#.
    row 2  #.#.....#
    row 1  ...#.#.#.
    row 0  #.#.....#

  two_pocket (11 gems)
    row 3  .....#.#.
    row 2  #.#.#....
    row 1  ...#.#.#.
    row 0  #...#...#

  chain_opportunity (14 gems)
    row 3  .#.#...#.
    row 2  ..#.#.#.#
    row 1  .#.#...#.
    row 0  #.#.#.#..

  sparse_top (12 gems)
    row 3  .#.....#.
    row 2  ..#.#.#..
    row 1  .#...#.#.
    row 0  #.#.#.#..

  dense_top (12 gems)
    row 3  .#...#.#.
    row 2  #.#.#.#..
    row 1  .#.....#.
    row 0  ..#.#.#..

Straight-lane safety across all archetypes, levels 1-120:
(a column open in EVERY row is a lane the player can shoot up all
level without ever aiming - the defect the seeded board prevents)
  levels with a straight lane: 0

================ 5. DIFFICULTY PROGRESSION ================
The curve must trend upward without being monotonic: a run of
ever-harder levels flattens into 'hard' and the spikes stop being
felt. '^' is a step up from the previous level, 'v' a relief dip.

lvl  band         role       template            rank  move
  1  TUTORIAL     challenge  tutorial_open       0     
  2  TUTORIAL     challenge  tutorial_seeded     0     
  3  EASY         challenge  relaxed             1    ^
  4  NORMAL       challenge  limited_generous    2    ^
  5  NORMAL       challenge  chain_friendly      2     
  6  NORMAL       challenge  limited_generous    2     
  7  EASY         challenge  recovery            1    v
  8  NORMAL       relief     limited_generous    2    ^
  9  EASY         challenge  recovery            1    v
 10  CHALLENGING  spike      precision           3    ^
 11  EASY         relief     recovery            1    v
 12  NORMAL       challenge  chain_friendly      2    ^
 13  CHALLENGING  spike      limited_dense       3    ^
 14  NORMAL       challenge  dense_opening       2    v
 15  CHALLENGING  challenge  precision           3    ^
 16  NORMAL       relief     limited_generous    2    v
 17  CHALLENGING  challenge  low_tier_build      3    ^
 18  CHALLENGING  spike      limited_dense       3     
 19  EASY         relief     recovery            1    v
 20  CHALLENGING  challenge  low_tier_build      3    ^
 21  HARD         spike      high_tier_build     4    ^
 22  CHALLENGING  challenge  limited_dense       3    v
 23  CHALLENGING  challenge  precision           3     
 24  EASY         relief     relaxed             1    v
 25  CHALLENGING  challenge  limited_dense       3    ^
 26  EXPERT       spike      expert_volume       5    ^
 27  NORMAL       relief     chain_friendly      2    v
 28  HARD         challenge  high_pressure       4    ^
 29  CHALLENGING  spike      limited_standard    3    v
 30  CHALLENGING  challenge  precision           3     
 31  HARD         challenge  limited_tight       4    ^
 32  EASY         relief     recovery            1    v
 33  HARD         challenge  high_tier_build     4    ^
 34  EXPERT       spike      expert_volume       5    ^
 35  NORMAL       relief     chain_friendly      2    v
 36  CHALLENGING  challenge  limited_dense       3    ^
 37  EXPERT       spike      expert_volume       5    ^
 38  CHALLENGING  challenge  precision           3    v
 39  HARD         challenge  limited_tight       4    ^
 40  NORMAL       relief     dense_opening       2    v
 41  HARD         challenge  limited_tight       4    ^
 42  EXPERT       spike      expert              5    ^
 43  CHALLENGING  relief     low_tier_build      3    v
 44  HARD         challenge  high_pressure       4    ^
 45  HARD         spike      limited_tight       4     
 46  EXPERT       challenge  expert              5    ^
 47  HARD         challenge  high_tier_build     4    v
 48  CHALLENGING  relief     limited_standard    3    v
 49  EXPERT       challenge  expert_volume       5    ^
 50  EXPERT       spike      expert              5     
 51  CHALLENGING  relief     low_tier_build      3    v
 52  CHALLENGING  challenge  limited_standard    3     
 53  EXPERT       spike      expert_volume       5    ^
 54  EXPERT       challenge  limited_expert      5     
 55  CHALLENGING  challenge  target_heavy        3    v
 56  NORMAL       relief     dense_opening       2    v
 57  EXPERT       challenge  expert_volume       5    ^
 58  EXPERT       spike      expert              5     
 59  CHALLENGING  relief     limited_standard    3    v
 60  HARD         challenge  high_pressure       4    ^

steps up: 27   relief dips: 21   (both non-zero = a real rhythm)
mean band rank, levels 1-40: 2.52   levels 61-100: 3.85

Limited-shot cadence (gaps between consecutive limited levels).
A single repeated gap would be the old metronome:
  limited levels: 4, 6, 8, 13, 16, 18, 22, 25, 29, 31, 36, 39, 41, 45, 48, 52, 54, 59, 62, 64, 68, 71, 75, 77, 82, 85, 87, 91, 94, 98, 100, 105, 108, 110, 114, 117
  gaps: 2 2 5 3 2 4 3 4 2 5 3 2 4 3 4 2 5 3 2 4 3 4 2 5 3 2 4 3 4 2 5 3 2 4 3 
    gap of 2: x11
    gap of 3: x10
    gap of 4: x9
    gap of 5: x5
  distinct gap lengths: 4

```
