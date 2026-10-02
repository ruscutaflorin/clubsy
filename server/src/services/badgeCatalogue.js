// Static badge catalogue. `kind` + `target` drive the evaluation in gamificationService.
export const BADGE_CATALOGUE = [
  {
    id: "first_pin",
    title: "First pin",
    description: "Make your first check-in.",
    kind: "checkIns",
    target: 1,
  },
  {
    id: "explorer_5",
    title: "Explorer",
    description: "Check in at 5 different clubs.",
    kind: "clubs",
    target: 5,
  },
  {
    id: "explorer_15",
    title: "Pathfinder",
    description: "Check in at 15 different clubs.",
    kind: "clubs",
    target: 15,
  },
  {
    id: "globetrotter_3",
    title: "Globetrotter",
    description: "Check in in 3 different cities.",
    kind: "cities",
    target: 3,
  },
  {
    id: "regular_5",
    title: "Regular",
    description: "Spend 5 nights at the same club.",
    kind: "regular",
    target: 5,
  },
  {
    id: "night_owl",
    title: "Night owl",
    description: "Check in between 03:00 and 05:59.",
    kind: "nightOwl",
    target: 1,
  },
  {
    id: "weekend_warrior",
    title: "Weekend warrior",
    description: "Go out on a Friday and a Saturday night in the same week.",
    kind: "weekend",
    target: 1,
  },
  {
    id: "streak_4",
    title: "On fire",
    description: "Go out 4 weeks in a row.",
    kind: "streak",
    target: 4,
  },
];
