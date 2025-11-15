import { useState, useEffect } from 'react';
import { ArrowLeft, RotateCcw, Trash2, Settings } from 'lucide-react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from './ui/dialog';
import { ConfigurationPanel } from './ConfigurationPanel';
import { TicTacToeBoard } from './TicTacToeBoard';
import { ScoreCard } from './ScoreCard';
import { toast } from 'sonner';
import type { GameMode, Player } from '../App';
import { motion } from 'motion/react';
import confetti from 'canvas-confetti';

interface GameScreenProps {
  mode: GameMode;
  players: [Player, Player];
  lunaStartsFirst: boolean;
  onBack: () => void;
  onUpdatePlayers: (players: [Player, Player]) => void;
  onToggleLunaStarts: (value: boolean) => void;
}

type Cell = string | null;
type Board = Cell[];

export function GameScreen({ 
  mode, 
  players, 
  lunaStartsFirst,
  onBack,
  onUpdatePlayers,
  onToggleLunaStarts
}: GameScreenProps) {
  const [board, setBoard] = useState<Board>(Array(9).fill(null));
  const [isPlayer1Turn, setIsPlayer1Turn] = useState(lunaStartsFirst);
  const [history, setHistory] = useState<Board[]>([]);
  const [scores, setScores] = useState({ player1: 0, draws: 0, player2: 0 });
  const [winner, setWinner] = useState<string | null>(null);
  const [winningLine, setWinningLine] = useState<number[] | null>(null);

  const isUnbeatableMode = mode === 'unbeatable';
  const currentPlayer = isPlayer1Turn ? players[0] : players[1];
  const player1Symbol = players[0].emoji;
  const player2Symbol = isUnbeatableMode ? '🤖' : players[1].emoji;

  useEffect(() => {
    if (!isPlayer1Turn && isUnbeatableMode && !winner && board.some(cell => cell === null)) {
      const timer = setTimeout(() => {
        makeAIMove();
      }, 500);
      return () => clearTimeout(timer);
    }
  }, [isPlayer1Turn, isUnbeatableMode, winner, board]);

  const calculateWinner = (squares: Board): { winner: string | null; line: number[] | null } => {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6] // diagonals
    ];

    for (const line of lines) {
      const [a, b, c] = line;
      if (squares[a] && squares[a] === squares[b] && squares[a] === squares[c]) {
        return { winner: squares[a], line };
      }
    }
    return { winner: null, line: null };
  };

  const minimax = (board: Board, depth: number, isMaximizing: boolean): number => {
    const { winner } = calculateWinner(board);
    
    if (winner === player2Symbol) return 10 - depth;
    if (winner === player1Symbol) return depth - 10;
    if (!board.includes(null)) return 0;

    if (isMaximizing) {
      let bestScore = -Infinity;
      for (let i = 0; i < 9; i++) {
        if (board[i] === null) {
          board[i] = player2Symbol;
          const score = minimax(board, depth + 1, false);
          board[i] = null;
          bestScore = Math.max(score, bestScore);
        }
      }
      return bestScore;
    } else {
      let bestScore = Infinity;
      for (let i = 0; i < 9; i++) {
        if (board[i] === null) {
          board[i] = player1Symbol;
          const score = minimax(board, depth + 1, true);
          board[i] = null;
          bestScore = Math.min(score, bestScore);
        }
      }
      return bestScore;
    }
  };

  const makeAIMove = () => {
    let bestScore = -Infinity;
    let bestMove = -1;
    const newBoard = [...board];

    for (let i = 0; i < 9; i++) {
      if (newBoard[i] === null) {
        newBoard[i] = player2Symbol;
        const score = minimax(newBoard, 0, false);
        newBoard[i] = null;
        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }

    if (bestMove !== -1) {
      handleCellClick(bestMove);
    }
  };

  const handleCellClick = (index: number) => {
    if (board[index] || winner) return;
    if (isUnbeatableMode && !isPlayer1Turn) return;

    const newBoard = [...board];
    newBoard[index] = isPlayer1Turn ? player1Symbol : player2Symbol;
    
    setHistory([...history, board]);
    setBoard(newBoard);

    const { winner: gameWinner, line } = calculateWinner(newBoard);
    
    if (gameWinner) {
      setWinner(gameWinner);
      setWinningLine(line);
      
      if (gameWinner === player1Symbol) {
        setScores(prev => ({ ...prev, player1: prev.player1 + 1 }));
        if (!isUnbeatableMode) {
          confetti({
            particleCount: 100,
            spread: 70,
            origin: { y: 0.6 }
          });
        }
        toast.success(`🎉 ¡${players[0].name} gana!`);
      } else {
        setScores(prev => ({ ...prev, player2: prev.player2 + 1 }));
        toast.error(isUnbeatableMode ? '🤖 La IA gana' : `🎉 ¡${players[1].name} gana!`);
      }
    } else if (!newBoard.includes(null)) {
      setWinner('draw');
      setScores(prev => ({ ...prev, draws: prev.draws + 1 }));
      toast('🤝 ¡Empate!');
    } else {
      setIsPlayer1Turn(!isPlayer1Turn);
    }
  };

  const handleUndo = () => {
    if (history.length === 0) return;
    
    const previousBoard = history[history.length - 1];
    setBoard(previousBoard);
    setHistory(history.slice(0, -1));
    setWinner(null);
    setWinningLine(null);
    setIsPlayer1Turn(!isPlayer1Turn);
  };

  const handleNewGame = () => {
    setBoard(Array(9).fill(null));
    setWinner(null);
    setWinningLine(null);
    setHistory([]);
    setIsPlayer1Turn(lunaStartsFirst);
  };

  const handleResetScores = () => {
    setScores({ player1: 0, draws: 0, player2: 0 });
    handleNewGame();
    toast.success('Puntuaciones reiniciadas');
  };

  const getBackgroundGradient = () => {
    if (isUnbeatableMode) {
      return 'from-blue-100 via-cyan-50 to-blue-100';
    }
    return 'from-pink-100 via-purple-50 to-pink-100';
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="space-y-6"
    >
      {/* Header */}
      <div className="flex items-center justify-between">
        <Button
          variant="ghost"
          size="icon"
          onClick={onBack}
          className="rounded-full bg-white shadow-md hover:bg-white/90"
        >
          <ArrowLeft className="size-5" />
        </Button>
        
        <div className="flex items-center gap-2">
          <span className="text-2xl">{isUnbeatableMode ? '🤖' : '🌙'}</span>
          <h2 className={isUnbeatableMode ? 'text-blue-600' : 'text-purple-600'}>
            {isUnbeatableMode ? 'Unbeatable Mode' : 'Luna Mode'}
          </h2>
        </div>

        <Dialog>
          <DialogTrigger asChild>
            <Button
              variant="ghost"
              size="icon"
              className="rounded-full bg-white shadow-md hover:bg-white/90"
            >
              <Settings className="size-5" />
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-md">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <Settings className="size-5" />
                Configuración
              </DialogTitle>
            </DialogHeader>
            <ConfigurationPanel 
              players={players}
              onUpdatePlayers={onUpdatePlayers}
              lunaStartsFirst={lunaStartsFirst}
              onToggleLunaStarts={onToggleLunaStarts}
            />
          </DialogContent>
        </Dialog>
      </div>

      {/* Score Cards */}
      <div className="grid grid-cols-3 gap-3">
        <ScoreCard
          icon={player1Symbol}
          label={players[0].name}
          score={scores.player1}
          color="red"
        />
        <ScoreCard
          icon="🏆"
          label="Empates"
          score={scores.draws}
          color="orange"
        />
        <ScoreCard
          icon={player2Symbol}
          label={isUnbeatableMode ? 'IA' : players[1].name}
          score={scores.player2}
          color="blue"
        />
      </div>

      {/* AI Warning */}
      {isUnbeatableMode && (
        <Card className="bg-gradient-to-r from-yellow-50 to-orange-50 border-yellow-200 p-3">
          <p className="text-sm text-center text-yellow-800 flex items-center justify-center gap-2">
            <span>⚠️</span>
            <span>IA usa algoritmo Minimax - ¡Es imbatible!</span>
          </p>
        </Card>
      )}

      {/* Turn Indicator */}
      {!winner && (
        <motion.div
          key={isPlayer1Turn ? 'p1' : 'p2'}
          initial={{ scale: 0.9, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          className="text-center"
        >
          <p className={`text-2xl ${isUnbeatableMode ? 'text-blue-600' : 'text-pink-600'}`}>
            Tu turno - ¡Buena suerte! 😊
          </p>
        </motion.div>
      )}

      {/* Game Board */}
      <TicTacToeBoard
        board={board}
        onCellClick={handleCellClick}
        winningLine={winningLine}
        disabled={!!winner || (isUnbeatableMode && !isPlayer1Turn)}
      />

      {/* Action Buttons */}
      <div className="flex gap-3">
        <Button
          onClick={handleNewGame}
          className={`flex-1 gap-2 ${isUnbeatableMode 
            ? 'bg-gradient-to-r from-blue-500 to-cyan-500 hover:from-blue-600 hover:to-cyan-600' 
            : 'bg-gradient-to-r from-pink-500 to-purple-500 hover:from-pink-600 hover:to-purple-600'
          } text-white shadow-lg`}
        >
          <RotateCcw className="size-4" />
          Nueva Partida
        </Button>

        {!isUnbeatableMode && (
          <Button
            onClick={handleUndo}
            disabled={history.length === 0}
            variant="outline"
            size="icon"
            className="shadow-md bg-white"
          >
            <ArrowLeft className="size-4" />
          </Button>
        )}

        <Button
          onClick={handleResetScores}
          variant="destructive"
          size="icon"
          className="shadow-md"
        >
          <Trash2 className="size-4" />
        </Button>
      </div>
    </motion.div>
  );
}