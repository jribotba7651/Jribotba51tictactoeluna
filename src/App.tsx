import { useState } from 'react';
import { HomeScreen } from './components/HomeScreen';
import { GameScreen } from './components/GameScreen';
import { Toaster } from './components/ui/sonner';

export type GameMode = 'luna' | 'unbeatable' | 'infinite' | null;

export interface Player {
  name: string;
  emoji: string;
}

export default function App() {
  const [gameMode, setGameMode] = useState<GameMode>(null);
  const [players, setPlayers] = useState<[Player, Player]>([
    { name: 'Luna', emoji: '🌙' },
    { name: 'Papá', emoji: '⭐' }
  ]);
  const [lunaStartsFirst, setLunaStartsFirst] = useState(true);

  return (
    <div className="min-h-screen bg-gradient-to-b from-pink-400 via-fuchsia-400 to-purple-500 flex items-center justify-center p-4">
      <div className="w-full max-w-6xl">
        {!gameMode ? (
          <HomeScreen
            onSelectMode={setGameMode}
            players={players}
            onUpdatePlayers={setPlayers}
            lunaStartsFirst={lunaStartsFirst}
            onToggleLunaStarts={setLunaStartsFirst}
          />
        ) : (
          <GameScreen
            mode={gameMode}
            players={players}
            lunaStartsFirst={lunaStartsFirst}
            onBack={() => setGameMode(null)}
            onUpdatePlayers={setPlayers}
            onToggleLunaStarts={setLunaStartsFirst}
          />
        )}
      </div>
      <Toaster />
    </div>
  );
}