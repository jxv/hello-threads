module HelloTVar.Main.Run
  ( run
  ) where

import HelloTVar.Main.Types (Chan(_writeChan, _readChan))
import HelloTVar.Main.Parts (Interthread(fork, newChan), Control(control), Broadcast(broadcast), Printy(printy))

run :: (Interthread m, Control m, Broadcast m, Printy m) => m ()
run = do
  chan <- newChan
  fork $ control (\number -> fork $ broadcast (_writeChan chan, number), 0)
  printy (_readChan chan)
