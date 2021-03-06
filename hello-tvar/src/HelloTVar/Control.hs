module HelloTVar.Control
  ( Console(..)
  , Forker(..)
  , HasNumber(..)
  , main
  , ControlM
  , runIO
  ) where

import Control.Monad (forever)
import Control.Monad.State (StateT, MonadState, get, put, evalStateT)
import Control.Monad.Reader (ReaderT, MonadReader, ask, runReaderT)
import Control.Monad.Error.Class (MonadError)
import Control.Monad.IO.Class (MonadIO(liftIO))
import Control.Exception.Safe (MonadCatch, MonadThrow)
import Control.Monad.Except (ExceptT(..), runExceptT)
import Data.Text (Text, unpack)
import qualified Data.Text.IO as T (getLine)

class Monad m => Console m where
  readLine :: m Text

class Monad m => Forker m where
  forkUpdater :: Int -> m ()

class Monad m => HasNumber m where
  getNumber :: m Int
  putNumber :: Int -> m ()


main :: (Console m, HasNumber m, Forker m) => m ()
main = forever step

step :: (Console m, HasNumber m, Forker m) => m ()
step = do
  _ <- readLine
  number <- getNumber
  forkUpdater number
  putNumber (number + 1)


newtype ControlM a = ControlM { unControlM :: ExceptT Text (ReaderT (Int -> IO ()) (StateT Int IO)) a }
  deriving (Functor, Applicative, Monad, MonadIO, MonadError Text, MonadCatch, MonadThrow, MonadState Int, MonadReader (Int -> IO ()))

runIO :: MonadIO m => ControlM a -> (Int -> IO (), Int) -> m a
runIO (ControlM m) (updater, number) = liftIO $ do
  result <- evalStateT (runReaderT (runExceptT m) updater) number
  either (error . unpack) return result

instance Console ControlM where
  readLine = liftIO T.getLine

instance HasNumber ControlM where
  putNumber = put
  getNumber = get

instance Forker ControlM where
  forkUpdater number = do
    f <- ask
    liftIO $ f number
