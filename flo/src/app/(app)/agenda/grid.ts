// Placement des rendez-vous dans la grille horaire (minutes depuis minuit).
export const toMin = (t: string) => Number(t.slice(0, 2)) * 60 + Number(t.slice(3, 5));

export type Placed<T> = { e: T; start: number; end: number; lane: number; lanes: number };

// Les rendez-vous qui se chevauchent (personnes différentes) sont mis côte à côte, comme dans Google Agenda.
export function layoutDay<T extends { start_time: string; end_time: string }>(events: T[]): Placed<T>[] {
  const items = events
    .map((e) => { const start = toMin(e.start_time); const end = toMin(e.end_time); return { e, start, end: end <= start ? 24 * 60 : end }; })
    .sort((a, b) => a.start - b.start || b.end - a.end);
  const out: Placed<T>[] = [];
  let group: (typeof items[number] & { lane: number })[] = [];
  let groupEnd = -1, laneEnds: number[] = [];
  const flush = () => {
    const lanes = Math.max(...group.map((g) => g.lane)) + 1;
    for (const g of group) out.push({ ...g, lanes });
    group = []; laneEnds = []; groupEnd = -1;
  };
  for (const it of items) {
    if (group.length && it.start >= groupEnd) flush();
    let lane = laneEnds.findIndex((end) => end <= it.start);
    if (lane < 0) lane = laneEnds.length;
    laneEnds[lane] = it.end;
    group.push({ ...it, lane });
    groupEnd = Math.max(groupEnd, it.end);
  }
  if (group.length) flush();
  return out;
}
