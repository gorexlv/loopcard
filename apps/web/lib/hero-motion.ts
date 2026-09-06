export const heroParticles = Array.from({ length: 24 }, (_, index) => ({
  id: `particle-${index + 1}`,
  x: (index * 37 + 11) % 101,
  y: (index * 61 + 17) % 101,
  size: 2 + (index % 4),
  delay: -((index * 1.7) % 18),
  duration: 12 + (index % 7) * 2.4,
  drift: -24 + (index % 9) * 6,
}));
