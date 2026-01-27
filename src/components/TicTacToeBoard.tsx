import { motion } from 'motion/react';

interface TicTacToeBoardProps {
  board: (string | null)[];
  onCellClick: (index: number) => void;
  winningLine: number[] | null;
  disabled?: boolean;
  rows?: number;
  cols?: number;
  cellSize?: number;
  lastMoveIndex?: number | null;
}

export function TicTacToeBoard({
  board,
  onCellClick,
  winningLine,
  disabled,
  rows = 3,
  cols = 3,
  cellSize = 130, // Default for 3x3
  lastMoveIndex = null
}: TicTacToeBoardProps) {
  const isLargeBoard = rows > 3 || cols > 3;

  // Calculate total dimensions
  const gap = isLargeBoard ? 4 : 8;
  const boardWidth = cols * cellSize + (cols - 1) * gap;
  const boardHeight = rows * cellSize + (rows - 1) * gap;

  return (
    <div className="relative p-4 md:p-8 max-w-full overflow-auto mx-auto flex justify-center">
      {/* Grid container */}
      <div
        className="relative"
        style={{
          width: `${boardWidth}px`,
          height: `${boardHeight}px`,
          zIndex: 1
        }}
      >
        {/* CSS-based grid lines for flexibility */}
        {!isLargeBoard && (
          <svg
            className="absolute inset-0 w-full h-full pointer-events-none"
            style={{ zIndex: 1 }}
            viewBox={`0 0 ${boardWidth} ${boardHeight}`}
          >
            {/* Horizontal lines */}
            {[...Array(rows - 1)].map((_, i) => (
              <path
                key={`h-${i}`}
                d={`M 20 ${(i + 1) * (cellSize + gap) - gap / 2} Q ${boardWidth / 2} ${(i + 1) * (cellSize + gap) - gap / 2 + 2}, ${boardWidth - 20} ${(i + 1) * (cellSize + gap) - gap / 2}`}
                stroke="rgba(255, 255, 255, 0.9)"
                strokeWidth="3"
                fill="none"
                strokeLinecap="round"
              />
            ))}
            {/* Vertical lines */}
            {[...Array(cols - 1)].map((_, i) => (
              <path
                key={`v-${i}`}
                d={`M ${(i + 1) * (cellSize + gap) - gap / 2} 20 Q ${(i + 1) * (cellSize + gap) - gap / 2 + 2} ${boardHeight / 2}, ${(i + 1) * (cellSize + gap) - gap / 2} ${boardHeight - 20}`}
                stroke="rgba(255, 255, 255, 0.9)"
                strokeWidth="3"
                fill="none"
                strokeLinecap="round"
              />
            ))}
          </svg>
        )}

        {/* Game cells */}
        <div
          className="grid relative h-full"
          style={{
            gridTemplateColumns: `repeat(${cols}, ${cellSize}px)`,
            gridTemplateRows: `repeat(${rows}, ${cellSize}px)`,
            gap: `${gap}px`,
            zIndex: 2
          }}
        >
          {board.map((cell, index) => {
            const isWinningCell = winningLine?.includes(index);
            const isLastMove = index === lastMoveIndex;
            const rotation = (index * 7) % 20 - 10;

            return (
              <motion.button
                key={index}
                onClick={() => onCellClick(index)}
                disabled={disabled || !!cell}
                whileHover={!cell && !disabled ? { scale: 1.05 } : {}}
                whileTap={!cell && !disabled ? { scale: 0.95 } : {}}
                className={`
                  relative flex items-center justify-center rounded-xl
                  transition-all duration-200
                  ${!cell && !disabled ? 'cursor-pointer hover:bg-white/20' : 'cursor-not-allowed'}
                  ${isLargeBoard ? 'bg-white/40 border border-black/5' : ''}
                `}
              >
                {/* Winning highlight */}
                {isWinningCell && (
                  <motion.div
                    initial={{ scale: 0, rotate: -45 }}
                    animate={{ scale: [1, 1.1, 1], rotate: 0 }}
                    transition={{
                      scale: { repeat: Infinity, duration: 1.5, ease: "easeInOut" }
                    }}
                    className="absolute inset-0 bg-yellow-300 rounded-xl blur-md opacity-60"
                    style={{ zIndex: -1 }}
                  />
                )}

                {/* Last move indicator */}
                {isLastMove && !isWinningCell && (
                  <motion.div
                    initial={{ opacity: 0, scale: 0.5 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="absolute inset-0 border-2 border-purple-400 rounded-xl pointer-events-none"
                    style={{ zIndex: 1 }}
                  />
                )}

                {/* Cell content */}
                {cell && (
                  <motion.div
                    initial={{ scale: 0, rotate: -180, opacity: 0 }}
                    animate={{
                      scale: 1,
                      rotate: rotation,
                      opacity: 1
                    }}
                    className="relative"
                    style={{ zIndex: 10 }}
                  >
                    <span
                      className="block select-none leading-none"
                      style={{
                        fontSize: `${cellSize * 0.8}px`,
                        filter: 'drop-shadow(2px 2px 2px rgba(0,0,0,0.3))',
                      }}>
                      {cell}
                    </span>
                  </motion.div>
                )}

                {/* Hover indicator (only for 3x3) */}
                {!isLargeBoard && !cell && !disabled && (
                  <motion.div
                    className="absolute inset-0 flex items-center justify-center pointer-events-none"
                    initial={{ opacity: 0, scale: 0.7 }}
                    whileHover={{ opacity: 0.4, scale: 1 }}
                    style={{ zIndex: 5 }}
                  >
                    <svg width={cellSize} height={cellSize} viewBox="0 0 120 120">
                      <path
                        d="M 60 15 Q 80 17, 95 35 T 105 60 Q 103 80, 85 95 T 60 105 Q 40 103, 25 85 T 15 60 Q 17 40, 35 25 T 60 15"
                        stroke="rgba(139, 92, 246, 0.7)"
                        strokeWidth="5"
                        fill="none"
                        strokeDasharray="10 8"
                        strokeLinecap="round"
                      />
                    </svg>
                  </motion.div>
                )}
              </motion.button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
