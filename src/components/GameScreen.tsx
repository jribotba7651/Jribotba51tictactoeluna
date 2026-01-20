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

export function GameScreen({
  mode,
  players,
  lunaStartsFirst,
  onBack,
  onUpdatePlayers,
  onToggleLunaStarts
}: GameScreenProps) {
  // Common state
  const [isPlayer1Turn, setIsPlayer1Turn] = useState(lunaStartsFirst);
  const [scores, setScores] = useState({ player1: 0, draws: 0, player2: 0 });
  const [winner, setWinner] = useState<string | null>(null);
  const [winningLine, setWinningLine] = useState<number[] | null>(null);
  const [lastMoveIndex, setLastMoveIndex] = useState<number | null>(null);

  // Standard Mode State (3x3)
  const [board, setBoard] = useState<Cell[]>(Array(9).fill(null));
  const [history, setHistory] = useState<Cell[][]>([]);

  // Infinite Mode State
  const [infiniteBoard, setInfiniteBoard] = useState<Record<string, string>>({});
  const [bounds, setBounds] = useState({ minRow: 0, maxRow: 4, minCol: 0, maxCol: 4 });

  const isUnbeatableMode = mode === 'unbeatable';
  const isInfiniteMode = mode === 'infinite';
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

  // --- Winning Logic ---

  const calculateStandardWinner = (squares: Cell[]): { winner: string | null; line: number[] | null } => {
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

  const checkInfiniteWinner = (row: number, col: number, symbol: string) => {
    const directions = [
      [0, 1],  // horizontal
      [1, 0],  // vertical
      [1, 1],  // diagonal top-left to bottom-right
      [1, -1]  // diagonal top-right to bottom-left
    ];

    for (const [dr, dc] of directions) {
      let count = 1;
      const line = [row * 1000 + col];

      // Check in one direction
      for (let i = 1; i < 5; i++) {
        if (infiniteBoard[`${row + dr * i},${col + dc * i}`] === symbol) {
          count++;
          line.push((row + dr * i) * 1000 + (col + dc * i));
        } else break;
      }

      // Check in opposite direction
      for (let i = 1; i < 5; i++) {
        if (infiniteBoard[`${row - dr * i},${col - dc * i}`] === symbol) {
          count++;
          line.push((row - dr * i) * 1000 + (col - dc * i));
        } else break;
      }

      if (count >= 5) return line;
    }
    return null;
  };

  // --- AI Logic (Standard Only) ---

  const minimax = (board: Cell[], depth: number, isMaximizing: boolean): number => {
    const { winner } = calculateStandardWinner(board);
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

    if (bestMove !== -1) handleCellClick(bestMove);
  };

  // --- Handlers ---

  const handleCellClick = (index: number) => {
    if (winner) return;
    const symbol = isPlayer1Turn ? player1Symbol : player2Symbol;

    if (isInfiniteMode) {
      const row = Math.floor(index / 1000);
      const col = index % 1000;
      if (infiniteBoard[`${row},${col}`]) return;

      const newInfiniteBoard = { ...infiniteBoard, [`${row},${col}`]: symbol };
      setInfiniteBoard(newInfiniteBoard);
      setLastMoveIndex(index);

      // Expand bounds if needed
      if (row <= bounds.minRow) setBounds(b => ({ ...b, minRow: b.minRow - 1 }));
      if (row >= bounds.maxRow) setBounds(b => ({ ...b, maxRow: b.maxRow + 1 }));
      if (col <= bounds.minCol) setBounds(b => ({ ...b, minCol: b.minCol - 1 }));
      if (col >= bounds.maxCol) setBounds(b => ({ ...b, maxCol: b.maxCol + 1 }));

      const winLine = checkInfiniteWinner(row, col, symbol);
      if (winLine) {
        setWinner(symbol);
        setWinningLine(winLine);
        finalizeWin(symbol);
      } else {
        setIsPlayer1Turn(!isPlayer1Turn);
      }
    } else {
      if (board[index]) return;
      if (isUnbeatableMode && !isPlayer1Turn) return;

      const newBoard = [...board];
      newBoard[index] = symbol;
      setHistory([...history, board]);
      setBoard(newBoard);
      setLastMoveIndex(index);

      const { winner: gameWinner, line } = calculateStandardWinner(newBoard);
      if (gameWinner) {
        setWinner(gameWinner);
        setWinningLine(line);
        finalizeWin(gameWinner);
      } else if (!newBoard.includes(null)) {
        setWinner('draw');
        setScores(prev => ({ ...prev, draws: prev.draws + 1 }));
        toast('🤝 ¡Empate!');
      } else {
        setIsPlayer1Turn(!isPlayer1Turn);
      }
    }
  };

  const finalizeWin = (gameWinner: string) => {
    if (gameWinner === player1Symbol) {
      setScores(prev => ({ ...prev, player1: prev.player1 + 1 }));
      confetti({ particleCount: 150, spread: 80, origin: { y: 0.6 } });
      toast.success(`🎉 ¡${players[0].name} gana!`);
    } else {
      setScores(prev => ({ ...prev, player2: prev.player2 + 1 }));
      toast.error(isUnbeatableMode ? '🤖 La IA gana' : `🎉 ¡${players[1].name} gana!`);
    }
  };

  const handleUndo = () => {
    if (isInfiniteMode || history.length === 0) return;
    const previousBoard = history[history.length - 1];
    setBoard(previousBoard);
    setHistory(history.slice(0, -1));
    setWinner(null);
    setWinningLine(null);
    setLastMoveIndex(null);
    setIsPlayer1Turn(!isPlayer1Turn);
  };

  const handleNewGame = () => {
    setBoard(Array(9).fill(null));
    setInfiniteBoard({});
    setBounds({ minRow: 0, maxRow: 4, minCol: 0, maxCol: 4 });
    setWinner(null);
    setWinningLine(null);
    setLastMoveIndex(null);
    setHistory([]);
    setIsPlayer1Turn(lunaStartsFirst);
  };

  const handleResetScores = () => {
    setScores({ player1: 0, draws: 0, player2: 0 });
    handleNewGame();
    toast.success('Puntuaciones reiniciadas');
  };

  // --- Rendering Helpers ---

  const getVisibleBoard = () => {
    if (!isInfiniteMode) return board;

    const rows = bounds.maxRow - bounds.minRow + 1;
    const cols = bounds.maxCol - bounds.minCol + 1;
    const visibleBoard: Cell[] = Array(rows * cols).fill(null);

    for (let r = bounds.minRow; r <= bounds.maxRow; r++) {
      for (let c = bounds.minCol; c <= bounds.maxCol; c++) {
        const symbol = infiniteBoard[`${r},${c}`];
        if (symbol) {
          const vRow = r - bounds.minRow;
          const vCol = c - bounds.minCol;
          visibleBoard[vRow * cols + vCol] = symbol;
        }
      }
    }
    return visibleBoard;
  };

  const mapGlobalIndexToLocal = (globalIndex: number) => {
    if (!isInfiniteMode) return globalIndex;
    const r = Math.floor(globalIndex / 1000);
    const c = globalIndex % 1000;
    const vRow = r - bounds.minRow;
    const vCol = c - bounds.minCol;
    return vRow * (bounds.maxCol - bounds.minCol + 1) + vCol;
  };

  const mapLocalIndexToGlobal = (localIndex: number) => {
    if (!isInfiniteMode) return localIndex;
    const cols = bounds.maxCol - bounds.minCol + 1;
    const vRow = Math.floor(localIndex / cols);
    const vCol = localIndex % cols;
    return (bounds.minRow + vRow) * 1000 + (bounds.minCol + vCol);
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <Button variant="ghost" size="icon" onClick={onBack} className="rounded-full bg-white shadow-md">
          <ArrowLeft className="size-5" />
        </Button>
        <div className="flex items-center gap-2">
          <span className="text-2xl">
            {isInfiniteMode ? '♾️' : isUnbeatableMode ? '🤖' : '🌙'}
          </span>
          <h2 className={isUnbeatableMode ? 'text-blue-600' : isInfiniteMode ? 'text-emerald-600' : 'text-purple-600'}>
            {isInfiniteMode ? 'Infinite Mode' : isUnbeatableMode ? 'Unbeatable Mode' : 'Luna Mode'}
          </h2>
        </div>
        <Dialog>
          <DialogTrigger asChild>
            <Button variant="ghost" size="icon" className="rounded-full bg-white shadow-md">
              <Settings className="size-5" />
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-md">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2"><Settings className="size-5" /> Configuración</DialogTitle>
            </DialogHeader>
            <ConfigurationPanel players={players} onUpdatePlayers={onUpdatePlayers} lunaStartsFirst={lunaStartsFirst} onToggleLunaStarts={onToggleLunaStarts} />
          </DialogContent>
        </Dialog>
      </div>

      {/* Score Cards */}
      <div className="grid grid-cols-3 gap-3">
        <ScoreCard icon={player1Symbol} label={players[0].name} score={scores.player1} color="red" />
        <ScoreCard icon="🏆" label="Empates" score={scores.draws} color="orange" />
        <ScoreCard icon={player2Symbol} label={isUnbeatableMode ? 'IA' : players[1].name} score={scores.player2} color="blue" />
      </div>

      {/* Info Card */}
      {(isUnbeatableMode || isInfiniteMode) && (
        <Card className={`bg-gradient-to-r p-3 border ${isUnbeatableMode ? 'from-blue-50 to-cyan-50 border-blue-200' : 'from-emerald-50 to-teal-50 border-emerald-200'}`}>
          <p className="text-sm text-center flex items-center justify-center gap-2">
            <span>{isUnbeatableMode ? '🤖 IA imbatible activada' : '♾️ Tablero infinito - Consigue 5 en línea'}</span>
          </p>
        </Card>
      )}

      {/* Turn Indicator */}
      {!winner && (
        <motion.div key={isPlayer1Turn ? 'p1' : 'p2'} initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="text-center">
          <p className={`text-2xl ${isInfiniteMode ? 'text-emerald-600' : isUnbeatableMode ? 'text-blue-600' : 'text-pink-600'}`}>
            Turno de {currentPlayer.name} {currentPlayer.emoji}
          </p>
        </motion.div>
      )}

      {/* Game Board */}
      <TicTacToeBoard
        board={getVisibleBoard()}
        onCellClick={(localIndex) => handleCellClick(mapLocalIndexToGlobal(localIndex))}
        winningLine={winningLine ? winningLine.map(mapGlobalIndexToLocal) : null}
        disabled={!!winner || (isUnbeatableMode && !isPlayer1Turn)}
        rows={isInfiniteMode ? bounds.maxRow - bounds.minRow + 1 : 3}
        cols={isInfiniteMode ? bounds.maxCol - bounds.minCol + 1 : 3}
        cellSize={isInfiniteMode ? 60 : 130}
        lastMoveIndex={lastMoveIndex !== null ? mapGlobalIndexToLocal(lastMoveIndex) : null}
      />

      {/* Action Buttons */}
      <div className="flex gap-3">
        <Button onClick={handleNewGame} className="flex-1 gap-2 bg-gradient-to-r from-pink-500 to-purple-500 text-white shadow-lg">
          <RotateCcw className="size-4" /> Nueva Partida
        </Button>
        {!isUnbeatableMode && !isInfiniteMode && (
          <Button onClick={handleUndo} disabled={history.length === 0} variant="outline" size="icon" className="shadow-md bg-white">
            <ArrowLeft className="size-4" />
          </Button>
        )}
        <Button onClick={handleResetScores} variant="destructive" size="icon" className="shadow-md">
          <Trash2 className="size-4" />
        </Button>
      </div>
    </motion.div>
  );
}
