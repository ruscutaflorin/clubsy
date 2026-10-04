// Shared Prisma `where` fragment for every social query. Spread it into a User filter (or a
// relation filter on a user) so a block hides both users from each other, in both directions.
export const visibleToUser = (viewerId) => ({
  blocksMade: { none: { blockedId: viewerId } },
  blocksReceived: { none: { blockerId: viewerId } },
});
