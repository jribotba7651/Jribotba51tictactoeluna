import { useState } from 'react';
import { Input } from './ui/input';
import { Switch } from './ui/switch';
import { Button } from './ui/button';
import { Separator } from './ui/separator';
import type { Player } from '../App';

interface ConfigurationPanelProps {
  players: [Player, Player];
  onUpdatePlayers: (players: [Player, Player]) => void;
  lunaStartsFirst: boolean;
  onToggleLunaStarts: (value: boolean) => void;
}

const availableEmojis = [
  '🌙', '🌈', '⭐', '💖', '🦄', '🌸', 
  '✨', '🪐', '🎀', '🌺', '🦋', '🌻',
  '🎨', '🎭', '🎪', '🎡'
];

export function ConfigurationPanel({ 
  players, 
  onUpdatePlayers,
  lunaStartsFirst,
  onToggleLunaStarts
}: ConfigurationPanelProps) {
  const [editingPlayer, setEditingPlayer] = useState<0 | 1>(0);
  const [localPlayers, setLocalPlayers] = useState(players);

  const handleNameChange = (index: 0 | 1, name: string) => {
    const newPlayers: [Player, Player] = [...localPlayers] as [Player, Player];
    newPlayers[index] = { ...newPlayers[index], name };
    setLocalPlayers(newPlayers);
    onUpdatePlayers(newPlayers);
  };

  const handleEmojiSelect = (index: 0 | 1, emoji: string) => {
    const newPlayers: [Player, Player] = [...localPlayers] as [Player, Player];
    newPlayers[index] = { ...newPlayers[index], emoji };
    setLocalPlayers(newPlayers);
    onUpdatePlayers(newPlayers);
  };

  return (
    <div className="space-y-6">
      {/* Player Configuration */}
      <div className="space-y-4">
        <div className="flex gap-2">
          <Button
            variant={editingPlayer === 0 ? 'default' : 'outline'}
            onClick={() => setEditingPlayer(0)}
            className="flex-1"
          >
            Jugador 1
          </Button>
          <Button
            variant={editingPlayer === 1 ? 'default' : 'outline'}
            onClick={() => setEditingPlayer(1)}
            className="flex-1"
          >
            Jugador 2
          </Button>
        </div>

        <div className="space-y-4 p-4 bg-gradient-to-br from-purple-50 to-pink-50 rounded-lg">
          <div>
            <label className="text-sm text-gray-600 mb-2 block">Nombre</label>
            <Input
              value={localPlayers[editingPlayer].name}
              onChange={(e) => handleNameChange(editingPlayer, e.target.value)}
              placeholder="Escribe un nombre..."
              className="bg-white"
            />
          </div>

          <div>
            <label className="text-sm text-gray-600 mb-3 block">
              Elige tu emoji:
            </label>
            <div className="grid grid-cols-4 gap-2 max-h-48 overflow-y-auto">
              {availableEmojis.map((emoji) => (
                <button
                  key={emoji}
                  onClick={() => handleEmojiSelect(editingPlayer, emoji)}
                  className={`
                    aspect-square rounded-lg flex items-center justify-center text-2xl
                    transition-all duration-200
                    ${localPlayers[editingPlayer].emoji === emoji
                      ? 'bg-gradient-to-br from-blue-500 to-purple-500 ring-2 ring-blue-400 ring-offset-2 scale-110'
                      : 'bg-white hover:bg-gray-50 border-2 border-gray-200 hover:border-blue-300'
                    }
                  `}
                >
                  {emoji}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      <Separator />

      {/* Game Options */}
      <div className="space-y-4">
        <div className="flex items-center gap-2 text-green-600">
          <span className="text-lg">⚙️</span>
          <h3>Opciones de Juego</h3>
        </div>

        <div className="flex items-center justify-between p-4 bg-gradient-to-r from-yellow-50 to-orange-50 rounded-lg border border-yellow-200">
          <div className="flex items-center gap-2">
            <span className="text-2xl">🌙</span>
            <span className="text-sm">Luna siempre empieza primero</span>
          </div>
          <Switch
            checked={lunaStartsFirst}
            onCheckedChange={onToggleLunaStarts}
          />
        </div>
      </div>
    </div>
  );
}
