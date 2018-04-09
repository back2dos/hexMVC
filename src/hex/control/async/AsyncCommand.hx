package hex.control.async;

import hex.control.async.AsyncCommandMessage;
import hex.control.async.IAsyncCommand;
import hex.control.async.IAsyncCommandListener;
import hex.di.IInjectorContainer;
import hex.error.IllegalStateException;
import hex.error.VirtualMethodException;
import hex.event.ClosureDispatcher;
import hex.log.ILogger;
import hex.module.IContextModule;
import hex.util.Stringifier;

/**
 * ...
 * @author Francis Bourre
 */
class AsyncCommand implements IAsyncCommand implements IInjectorContainer
{
    public static inline var WAS_NEVER_USED     : String = "WAS_NEVER_USED";
    public static inline var IS_RUNNING         : String = "IS_RUNNING";
    public static inline var IS_COMPLETED       : String = "IS_COMPLETED";
    public static inline var IS_FAILED          : String = "IS_FAILED";
    public static inline var IS_CANCELLED       : String = "IS_CANCELLED";

    var _status                         : String;
    var _dispatcher 					: ClosureDispatcher;
    var _owner                          : IContextModule;

	@Inject
	@Optional(true)
	public var logger:ILogger;
	
    public function new()
    {
        this._status 			= AsyncCommand.WAS_NEVER_USED;
        this._dispatcher        = new ClosureDispatcher();
    }
	
	public function execute() : Void
	{
		throw new VirtualMethodException();
	}
	
	public function getLogger() : ILogger
	{
		return (logger == null) ? _owner.getLogger() : logger;
	}

    public function preExecute( ?request : Request ) : Void
    {
        this.wasUsed && this._throwExecutionIllegalStateError();
        this._status = AsyncCommand.IS_RUNNING;
        AsyncCommand.detain( this );
    }

    public function cancel() : Void
    {
        this._handleCancel();
    }

    public function addAsyncCommandListener( listener : IAsyncCommandListener ) : Void
    {
		this.addCompleteHandler( listener.onAsyncCommandComplete );
        this.addFailHandler( listener.onAsyncCommandFail );
        this.addCancelHandler( listener.onAsyncCommandCancel );
    }

    public function removeAsyncCommandListener( listener : IAsyncCommandListener ) : Void
    {
		this.removeCompleteHandler( listener.onAsyncCommandComplete );
        this.removeFailHandler( listener.onAsyncCommandFail );
        this.removeCancelHandler( listener.onAsyncCommandCancel );
    }

    public function addCompleteHandler( callback : AsyncCommand->Void ) : Void
    {
        if ( this.hasCompleted )
        {
            callback( this );
        }
        else
        {
            this._dispatcher.addHandler( AsyncCommandMessage.COMPLETE, callback );
        }
    }

    public function removeCompleteHandler( callback : AsyncCommand->Void ) : Void
    {
        this._dispatcher.removeHandler( AsyncCommandMessage.COMPLETE, callback );
    }

    public function addFailHandler( callback : AsyncCommand->Void ) : Void
    {
        if ( this.hasFailed )
        {
            callback( this );
        }
        else
        {
            this._dispatcher.addHandler( AsyncCommandMessage.FAIL, callback );
        }
    }

    public function removeFailHandler( callback : AsyncCommand->Void ) : Void
    {
        this._dispatcher.removeHandler( AsyncCommandMessage.FAIL, callback );
    }

    public function addCancelHandler( callback : AsyncCommand->Void ) : Void
    {
        if ( this.isCancelled )
        {
            callback( this );
        }
        else
        {
            this._dispatcher.addHandler( AsyncCommandMessage.CANCEL, callback );
        }
    }

    public function removeCancelHandler( callback : AsyncCommand->Void ) : Void
    {
        this._dispatcher.removeHandler( AsyncCommandMessage.CANCEL, callback );
    }

	@:final 
    function _handleComplete() : Void
    {
		this.wasUsed && this._status != AsyncCommand.IS_RUNNING && this._throwIllegalStateError( '_handleComplete' );
        this._status = AsyncCommand.IS_COMPLETED;
        this._dispatcher.dispatch( AsyncCommandMessage.COMPLETE, [ this ] );
        this._release();
    }

	@:final 
    function _handleFail() : Void
    {
		this.wasUsed && this._status != AsyncCommand.IS_RUNNING && this._throwIllegalStateError( '_handleFail' );
        this._status = AsyncCommand.IS_FAILED;
        this._dispatcher.dispatch( AsyncCommandMessage.FAIL, [ this ] );
        this._release();
    }

	@:final 
    function _handleCancel() : Void
    {
		this.wasUsed && this._status != AsyncCommand.IS_RUNNING && this._throwIllegalStateError( '_handleCancel' );
        this._status = AsyncCommand.IS_CANCELLED;
        this._dispatcher.dispatch( AsyncCommandMessage.CANCEL, [ this ] );
        this._release();
    }

	public var wasUsed( get, null ) : Bool;
	@:final 
    public function get_wasUsed() : Bool
    {
        return this._status != AsyncCommand.WAS_NEVER_USED;
    }

	public var isRunning( get, null ) : Bool;
	@:final
    public function get_isRunning() : Bool
    {
        return this._status == AsyncCommand.IS_RUNNING;
    }

	public var hasCompleted( get, null ) : Bool;
	@:final 
    public function get_hasCompleted() : Bool
    {
        return this._status == AsyncCommand.IS_COMPLETED;
    }

	public var hasFailed( get, null ) : Bool;
	@:final 
    public function get_hasFailed() : Bool
    {
        return this._status == AsyncCommand.IS_FAILED;
    }

	public var isCancelled( get, null ) : Bool;
	@:final 
    public function get_isCancelled() : Bool
    {
        return this._status == AsyncCommand.IS_CANCELLED;
    }

	public function getResult() : Array<Dynamic>
    {
        return null;
    }
	
    public function getOwner() : IContextModule
    {
        return this._owner;
    }

    public function setOwner( owner : IContextModule ) : Void
    {
        if ( this._owner == null )
        {
            this._owner = owner;
        }
    }

    /**
     * Private
     */
    function _removeAllListeners() : Void
    {
        this._dispatcher.removeAllListeners();
    }

    function _throwExecutionIllegalStateError() : Bool
    {
        var msg : String = "";

        if ( this.isRunning )
        {
            msg = "'execute' call failed. This command is already processing.";
        }
        else if ( this.isCancelled )
        {
            msg = "'execute' call failed. This command is cancelled.";
        }
        else if ( this.hasCompleted )
        {
            msg = "'execute' call failed. This command is completed and can't be executed twice.";
        }
        else if ( this.hasFailed )
        {
            msg = "'execute' call failed. This command has failed and can't be executed twice.";
        }
		else if ( !this.wasUsed )
		{
			msg = "'execute' call failed. 'preExecute' should be called before.";
		}

        this._release();
        throw new IllegalStateException( msg );
    }
	
	function _throwIllegalStateError( process : String ) : Bool
    {
        var msg : String = "";

        if ( isCancelled )
        {
            msg = "'" + process + "' call failed in '" + Stringifier.stringify( this ) + "'. This command was already cancelled.";
        }
        else if ( hasCompleted )
        {
            msg = "'" + process + "' call failed in '" + Stringifier.stringify( this ) + "'. This command was already completed.";
        }
        else if ( hasFailed )
        {
            msg = "'" + process + "' call failed in '" + Stringifier.stringify( this ) + "'. This command has already failed.";
        }

        this._release();
        throw new IllegalStateException( msg );
    }

    function _release() : Void
    {
        this._removeAllListeners();
        AsyncCommand.release( this );
    }

    /**
     * Memory handling
     */
    static var _POOL = new Map<AsyncCommand, Bool>();

    static function isDetained( aSynCommand : AsyncCommand ) : Bool
    {
        return AsyncCommand._POOL.exists( aSynCommand );
    }

    static function detain( aSynCommand : AsyncCommand ) : Void
    {
        AsyncCommand._POOL.set( aSynCommand, true );
    }

    static function release( aSynCommand : AsyncCommand ) : Void
    {
        if ( AsyncCommand._POOL.exists( aSynCommand ) )
        {
            AsyncCommand._POOL.remove( aSynCommand );
        }
    }
}
