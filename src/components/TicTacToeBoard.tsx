import { motion } from 'motion/react';

interface TicTacToeBoardProps {
  board: (string | null)[];
  onCellClick: (index: number) => void;
  winningLine: number[] | null;
  disabled?: boolean;
}

export function TicTacToeBoard({ board, onCellClick, winningLine, disabled }: TicTacToeBoardProps) {
  return (
    <div className="relative p-12 max-w-4xl mx-auto">
      {/* Background paper texture */}
      <div 
        className="absolute inset-0 bg-gradient-to-br from-purple-50 via-pink-50 to-blue-50 rounded-3xl shadow-2xl" 
        style={{
          backgroundImage: `
            repeating-linear-gradient(
              0deg,
              transparent,
              transparent 20px,
              rgba(203, 213, 225, 0.1) 20px,
              rgba(203, 213, 225, 0.1) 21px
            )
          `,
          border: '3px solid rgba(167, 139, 250, 0.2)'
        }}
      />
      
      {/* Hand-drawn grid container */}
      <div className="relative" style={{ width: '560px', height: '560px', margin: '0 auto' }}>
        {/* Hand-drawn # grid lines */}
        <svg 
          className="absolute inset-0 w-full h-full pointer-events-none" 
          style={{ zIndex: 1 }}
          viewBox="0 0 560 560"
        >
          {/* Primera línea vertical (izquierda) */}
          <path
            d="M 186 20 Q 184 100, 187 180 T 185 280 Q 186 360, 187 440 T 186 540"
            stroke="#374151"
            strokeWidth="8"
            fill="none"
            opacity="0.9"
            strokeLinecap="round"
            strokeLinejoin="round"
            style={{
              filter: 'drop-shadow(2px 2px 1px rgba(0,0,0,0.25))'
            }}
          />
          
          {/* Segunda línea vertical (derecha) */}
          <path
            d="M 374 20 Q 376 100, 373 180 T 375 280 Q 374 360, 373 440 T 374 540"
            stroke="#374151"
            strokeWidth="8"
            fill="none"
            opacity="0.9"
            strokeLinecap="round"
            strokeLinejoin="round"
            style={{
              filter: 'drop-shadow(2px 2px 1px rgba(0,0,0,0.25))'
            }}
          />
          
          {/* Primera línea horizontal (arriba) */}
          <path
            d="M 20 186 Q 100 184, 180 187 T 280 185 Q 360 186, 440 187 T 540 186"
            stroke="#374151"
            strokeWidth="8"
            fill="none"
            opacity="0.9"
            strokeLinecap="round"
            strokeLinejoin="round"
            style={{
              filter: 'drop-shadow(2px 2px 1px rgba(0,0,0,0.25))'
            }}
          />
          
          {/* Segunda línea horizontal (abajo) */}
          <path
            d="M 20 374 Q 100 376, 180 373 T 280 375 Q 360 374, 440 373 T 540 374"
            stroke="#374151"
            strokeWidth="8"
            fill="none"
            opacity="0.9"
            strokeLinecap="round"
            strokeLinejoin="round"
            style={{
              filter: 'drop-shadow(2px 2px 1px rgba(0,0,0,0.25))'
            }}
          />
        </svg>

        {/* Game cells */}
        <div className="grid grid-cols-3 gap-0 relative h-full" style={{ zIndex: 2 }}>
          {board.map((cell, index) => {
            const isWinningCell = winningLine?.includes(index);
            const rotation = (index * 7) % 15 - 7;
            
            return (
              <motion.button
                key={index}
                onClick={() => onCellClick(index)}
                disabled={disabled || !!cell}
                whileHover={!cell && !disabled ? { scale: 1.05 } : {}}
                whileTap={!cell && !disabled ? { scale: 0.95 } : {}}
                className={`
                  relative flex items-center justify-center
                  transition-all duration-200
                  ${!cell && !disabled ? 'cursor-pointer' : 'cursor-not-allowed'}
                `}
              >
                {/* Winning highlight */}
                {isWinningCell && (
                  <motion.div
                    initial={{ scale: 0, rotate: -45 }}
                    animate={{ 
                      scale: [1, 1.2, 1],
                      rotate: 0
                    }}
                    transition={{
                      scale: {
                        repeat: Infinity,
                        duration: 1.5,
                        ease: "easeInOut"
                      }
                    }}
                    className="absolute inset-0 bg-gradient-to-br from-yellow-300 to-orange-300 rounded-3xl blur-3xl opacity-60"
                    style={{ zIndex: -1 }}
                  />
                )}
                
                {/* Hover background */}
                {!cell && !disabled && (
                  <motion.div
                    className="absolute inset-0 rounded-2xl flex items-center justify-center"
                    initial={{ opacity: 0 }}
                    whileHover={{ opacity: 1 }}
                    style={{ zIndex: 0 }}
                  >
                    <div 
                      className="w-32 h-32 rounded-full"
                      style={{
                        background: 'radial-gradient(circle, rgba(167, 139, 250, 0.2) 0%, transparent 70%)',
                      }}
                    />
                  </motion.div>
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
                    transition={{ 
                      type: 'spring', 
                      stiffness: 200, 
                      damping: 15
                    }}
                    className="relative"
                    style={{ zIndex: 10 }}
                  >
                    <span 
                      className="block select-none"
                      style={{
                        fontSize: '130px',
                        lineHeight: 1,
                        filter: 'drop-shadow(4px 4px 3px rgba(0,0,0,0.3))',
                        textShadow: '3px 3px 6px rgba(0,0,0,0.15)'
                      }}>
                      {cell}
                    </span>
                  </motion.div>
                )}
                
                {/* Hover indicator - círculo punteado dibujado a mano */}
                {!cell && !disabled && (
                  <motion.div
                    className="absolute inset-0 flex items-center justify-center"
                    initial={{ opacity: 0, scale: 0.7 }}
                    whileHover={{ opacity: 0.6, scale: 1 }}
                    transition={{ duration: 0.2 }}
                    style={{ zIndex: 5 }}
                  >
                    <svg width="120" height="120" viewBox="0 0 120 120">
                      {/* Hand-drawn dashed circle */}
                      <path
                        d="M 60 15 Q 80 17, 95 35 T 105 60 Q 103 80, 85 95 T 60 105 Q 40 103, 25 85 T 15 60 Q 17 40, 35 25 T 60 15"
                        stroke="rgba(139, 92, 246, 0.7)"
                        strokeWidth="5"
                        fill="none"
                        strokeDasharray="10 8"
                        strokeLinecap="round"
                        style={{
                          filter: 'drop-shadow(2px 2px 2px rgba(0,0,0,0.2))'
                        }}
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
