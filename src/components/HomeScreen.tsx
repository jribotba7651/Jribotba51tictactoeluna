import { Gamepad2, ChevronRight, Settings } from 'lucide-react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from './ui/dialog';
import { ConfigurationPanel } from './ConfigurationPanel';
import type { GameMode, Player } from '../App';
import { motion } from 'motion/react';

interface HomeScreenProps {
  onSelectMode: (mode: GameMode) => void;
  players: [Player, Player];
  onUpdatePlayers: (players: [Player, Player]) => void;
  lunaStartsFirst: boolean;
  onToggleLunaStarts: (value: boolean) => void;
}

export function HomeScreen({
  onSelectMode,
  players,
  onUpdatePlayers,
  lunaStartsFirst,
  onToggleLunaStarts
}: HomeScreenProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-8"
    >
      {/* Header */}
      <div className="text-center space-y-4">
        <div className="flex items-center justify-center gap-3">
          <Gamepad2 className="size-12 text-gray-700" />
          <h1 className="bg-gradient-to-r from-pink-600 via-purple-600 to-pink-600 bg-clip-text text-transparent text-6xl">
            Tic-Tac-Toe
          </h1>
          <Gamepad2 className="size-12 text-gray-700" />
        </div>
        <p className="text-gray-600 text-xl">Elige tu modo de juego</p>
      </div>

      {/* Game Mode Cards */}
      <div className="space-y-4">
        {/* Luna Mode */}
        <motion.div
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          <Card
            className="relative overflow-hidden cursor-pointer border-0 shadow-lg hover:shadow-xl transition-all"
            onClick={() => onSelectMode('luna')}
          >
            <div className="absolute inset-0 bg-gradient-to-br from-pink-500 via-purple-500 to-orange-400" />
            <div className="relative p-6 space-y-4">
              <div className="flex items-start justify-between">
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <span className="text-5xl">🌙</span>
                    <div>
                      <h2 className="text-white">Luna Mode</h2>
                      <p className="text-white/90 text-sm">Juega con familia y amigos</p>
                    </div>
                  </div>
                </div>
                <ChevronRight className="size-6 text-white mt-2" />
              </div>

              <div className="space-y-2 text-white/95">
                <div className="flex items-center gap-2 text-sm">
                  <span className="size-5 rounded-full bg-white/20 flex items-center justify-center">✓</span>
                  <span>Emojis y nombres 🌈</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="size-5 rounded-full bg-white/20 flex items-center justify-center">✓</span>
                  <span>Confeti y animaciones 🎉</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="size-5 rounded-full bg-white/20 flex items-center justify-center">✓</span>
                  <span>Botón de deshacer 🔙</span>
                </div>
              </div>
            </div>
          </Card>
        </motion.div>

        {/* Unbeatable Mode */}
        <motion.div
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          <Card
            className="relative overflow-hidden cursor-pointer border-0 shadow-lg hover:shadow-xl transition-all"
            onClick={() => onSelectMode('unbeatable')}
          >
            <div className="absolute inset-0 bg-gradient-to-br from-blue-500 via-cyan-500 to-blue-600" />
            <div className="relative p-6 space-y-4">
              <div className="flex items-start justify-between">
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <span className="text-5xl">🤖</span>
                    <div>
                      <h2 className="text-white">Unbeatable Mode</h2>
                      <p className="text-white/90 text-sm">Desafía a la IA imposible</p>
                    </div>
                  </div>
                </div>
                <ChevronRight className="size-6 text-white mt-2" />
              </div>

              <div className="space-y-2 text-white/95">
                <div className="flex items-center gap-2 text-sm">
                  <span className="size-5 rounded-full bg-white/20 flex items-center justify-center">✓</span>
                  <span>IA imbatible</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="size-5 rounded-full bg-white/20 flex items-center justify-center">✓</span>
                  <span>Algoritmo Minimax</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="size-5 rounded-full bg-white/20 flex items-center justify-center">✓</span>
                  <span>¡Atrévete a intentarlo!</span>
                </div>
              </div>
            </div>
          </Card>
        </motion.div>

        {/* Infinite Mode */}
        <motion.div
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          <Card
            className="relative overflow-hidden cursor-pointer border-0 shadow-lg hover:shadow-xl transition-all"
            onClick={() => onSelectMode('infinite')}
          >
            <div className="absolute inset-0 bg-gradient-to-br from-emerald-500 via-teal-500 to-cyan-600" />
            <div className="relative p-6 space-y-4">
              <div className="flex items-start justify-between">
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <span className="text-5xl">♾️</span>
                    <div>
                      <h2 className="text-white">Infinite Mode</h2>
                      <p className="text-white/90 text-sm">El tablero crece contigo</p>
                    </div>
                  </div>
                </div>
                <ChevronRight className="size-6 text-white mt-2" />
              </div>

              <div className="space-y-2 text-white/95">
                <div className="flex items-center gap-2 text-sm">
                  <span className="size-5 rounded-full bg-white/20 flex items-center justify-center">✓</span>
                  <span>Tablero dinámico</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="size-5 rounded-full bg-white/20 flex items-center justify-center">✓</span>
                  <span>Consigue 5 en línea</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="size-5 rounded-full bg-white/20 flex items-center justify-center">✓</span>
                  <span>Sin límites de espacio</span>
                </div>
              </div>
            </div>
          </Card>
        </motion.div>
      </div>

      {/* Settings Button */}
      <Dialog>
        <DialogTrigger asChild>
          <Button variant="outline" className="w-full gap-2 bg-white/50 backdrop-blur-sm border-white/20">
            <Settings className="size-4" />
            Configuración
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

      {/* Footer */}
      <div className="text-center space-y-1">
        <p className="text-sm text-gray-600">
          Hecho con 💖 para Luna
        </p>
        <p className="text-xs text-gray-500">
          Versión 2.1 🌈✨
        </p>
      </div>
    </motion.div>
  );
}