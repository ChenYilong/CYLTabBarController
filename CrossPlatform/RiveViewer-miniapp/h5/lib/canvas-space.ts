export type AlignmentMatrix = {
  xx: number;
  xy: number;
  yx: number;
  yy: number;
  tx: number;
  ty: number;
};

export function canvasPointToBacking(
  x: number,
  y: number,
  cssWidth: number,
  cssHeight: number,
  backingWidth: number,
  backingHeight: number,
): { x: number; y: number } {
  return {
    x: x * (backingWidth / Math.max(1, cssWidth)),
    y: y * (backingHeight / Math.max(1, cssHeight)),
  };
}

export function backingPointToArtboard(
  matrix: AlignmentMatrix,
  x: number,
  y: number,
): { x: number; y: number } | null {
  const determinant = matrix.xx * matrix.yy - matrix.yx * matrix.xy;
  if (!determinant) return null;
  const translatedX = x - matrix.tx;
  const translatedY = y - matrix.ty;
  return {
    x: (matrix.yy * translatedX - matrix.yx * translatedY) / determinant,
    y: (-matrix.xy * translatedX + matrix.xx * translatedY) / determinant,
  };
}
