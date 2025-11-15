import { Card } from './ui/card';
import { motion } from 'motion/react';

interface ScoreCardProps {
  icon: string;
  label: string;
  score: number;
  color: 'red' | 'orange' | 'blue';
}

export function ScoreCard({ icon, label, score, color }: ScoreCardProps) {
  const colorClasses = {
    red: 'from-red-500 to-pink-500',
    orange: 'from-orange-500 to-yellow-500',
    blue: 'from-blue-500 to-cyan-500'
  };

  return (
    <Card className="p-6 bg-white shadow-lg border-0 text-center space-y-3">
      <div className="flex flex-col items-center gap-2">
        <span className="text-5xl">{icon}</span>
        <p className={`text-sm ${
          color === 'red' ? 'text-red-600' : 
          color === 'orange' ? 'text-orange-600' : 
          'text-blue-600'
        }`}>
          {label}
        </p>
      </div>
      <motion.div
        key={score}
        initial={{ scale: 1.5, color: '#000' }}
        animate={{ scale: 1, color: 'inherit' }}
        transition={{ duration: 0.3 }}
        className={`bg-gradient-to-r ${colorClasses[color]} bg-clip-text text-transparent text-5xl`}
      >
        {score}
      </motion.div>
    </Card>
  );
}