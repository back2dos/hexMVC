package hex.module;

import haxe.macro.Expr;
import hex.config.stateful.IStatefulConfig;
import hex.config.stateless.IStatelessConfig;
import hex.control.FrontController;
import hex.control.IFrontController;
import hex.control.Request;
import hex.control.macro.IMacroExecutor;
import hex.control.macro.MacroExecutor;
import hex.core.IApplicationContext;
import hex.di.Dependency;
import hex.di.IBasicInjector;
import hex.di.IDependencyInjector;
import hex.di.Injector;
import hex.di.provider.DomainLoggerProvider;
import hex.di.util.InjectorUtil;
import hex.domain.ApplicationDomainDispatcher;
import hex.domain.Domain;
import hex.domain.DomainExpert;
import hex.error.IllegalStateException;
import hex.error.VirtualMethodException;
import hex.event.Dispatcher;
import hex.event.IDispatcher;
import hex.event.MessageType;
import hex.log.ILogger;
import hex.log.LogManager;
import hex.log.message.DomainMessageFactory;
import hex.module.IModule;
import hex.view.IView;
import hex.view.viewhelper.IViewHelperTypedef;
import hex.view.viewhelper.ViewHelperManager;

/**
 * ...
 * @author Francis Bourre
 */
class Module implements IModule
{
	var _internalDispatcher 	: IDispatcher<{}>;
	var _domainDispatcher 		: IDispatcher<{}>;
	var _injector 				: Injector;
	var _logger 				: ILogger;

	public function new()
	{
		this._injector = new Injector();
		this._injector.mapToValue( IBasicInjector, this._injector );
		this._injector.mapToValue( IDependencyInjector, this._injector );
		
		this._internalDispatcher = new Dispatcher<{}>();
		this._injector.mapToValue( IFrontController, new FrontController( this._internalDispatcher, this._injector, this ) );
		this._injector.mapClassNameToValue( 'hex.event.IDispatcher<{}>', this._internalDispatcher );
		this._injector.mapToType( IMacroExecutor, MacroExecutor );
		this._injector.mapToValue( IContextModule, this );
		this._injector.mapToValue( IModule, this );
		
		
		var factory = new DomainMessageFactory( this.getDomain() );
		this._logger = LogManager.getLoggerByInstance( this, factory );
		this._injector.map( ILogger ).toProvider( new DomainLoggerProvider( factory, this._logger ) );
	}
			
	/**
	 * Initialize the module
	 */
	@:final 
	public function initialize( context : IApplicationContext ) : Void
	{
		#if debug
		if ( !this.isInitialized )
		{
		#end
			this._domainDispatcher = ApplicationDomainDispatcher.getInstance( context ).getDomainDispatcher( this.getDomain() );
			this._onInitialisation();
			
			#if debug
			this._checkRuntimeDependencies( this._getRuntimeDependencies() );
			#end
			
			this.isInitialized = true;
		#if debug
		}
		else throw new IllegalStateException( "initialize can't be called more than once. Check your code." );
		#end
	}

	/**
	 * Accessor for module initialisation state
	 * @return <code>true</code> if the module is initialized
	 */
	@:isVar public var isInitialized( get, null ) : Bool;
	@:final 
	function get_isInitialized() : Bool
	{
		return this.isInitialized;
	}

	/**
	 * Accessor for module release state
	 * @return <code>true</code> if the module is released
	 */
	@:isVar public var isReleased( get, null ) : Bool;
	@:final 
	public function get_isReleased() : Bool
	{
		return this.isReleased;
	}

	/**
	 * Get module's domain
	 * @return Domain
	 */
	public function getDomain() : Domain
	{
		return DomainExpert.getInstance().getDomainFor( this );
	}

	/**
	 * Sends an event outside of the module
	 * @param	event
	 */
	public function dispatchPublicMessage( messageType : MessageType, ?data : Array<Dynamic> ) : Void
	{
		#if debug
		if ( this._domainDispatcher != null )
		#end
			this._domainDispatcher.dispatch( messageType, data );
		#if debug
		else throw new IllegalStateException( "Domain dispatcher is null. Try to use 'Module.registerInternalDomain' before calling super constructor to fix the problem");
		#end
	}
	
	/**
	 * Add callback for specific message type
	 */
	public function addHandler( messageType : MessageType, scope : Dynamic, callback : haxe.Constraints.Function ) : Void
	{
		#if debug
		if ( this._domainDispatcher != null )
		#end
			this._domainDispatcher.addHandler( messageType, scope, callback );
		#if debug
		else throw new IllegalStateException( "Domain dispatcher is null. Try to use 'Module.registerInternalDomain' before calling super constructor to fix the problem");
		#end
	}

	/**
	 * Remove callback for specific message type
	 */
	public function removeHandler( messageType : MessageType, scope : Dynamic, callback : haxe.Constraints.Function ) : Void
	{
		#if debug
		if ( this._domainDispatcher != null )
		#end
			this._domainDispatcher.removeHandler( messageType, scope, callback );
		#if debug
		else throw new IllegalStateException( "Domain dispatcher is null. Try to use 'Module.registerInternalDomain' before calling super constructor to fix the problem");
		#end
	}
	
	function _dispatchPrivateMessage( messageType : MessageType, ?request : Request ) : Void
	{
		this._internalDispatcher.dispatch( messageType, [request] );
	}

	function buildViewHelper( type : Class<IViewHelperTypedef>, view : IView ) : IViewHelperTypedef
	{
		return ViewHelperManager.getInstance( this ).buildViewHelper( this._injector, type, view );
	}

	/**
	 * Release this module
	 */
	@:final 
	public function release() : Void
	{
		#if debug
		if ( !this.isReleased )
		{
		#end
			this.isReleased = true;
			this._onRelease();

			ViewHelperManager.release( this );
			
			if ( this._domainDispatcher != null )
			{
				this._domainDispatcher.removeAllListeners();
			}
			
			this._internalDispatcher.removeAllListeners();
			DomainExpert.getInstance().releaseDomain( this );

			this._injector.destroyInstance( this );
			this._injector.teardown();
			
			this._logger = null;
		#if debug
		}
		else throw new IllegalStateException( this + ".release can't be called more than once. Check your code." );
		#end
	}
	
	public function getInjector() : IDependencyInjector
	{
		return this._injector;
	}
	
	public function getLogger() : ILogger
	{
		return this._logger;
	}
	
	/**
	 * Override and implement
	 */
	function _onInitialisation() : Void
	{

	}

	/**
	 * Override and implement
	 */
	function _onRelease() : Void
	{

	}
	
	/**
	 * Accessor for dependecy injector
	 * @return <code>IDependencyInjector</code> used by this module
	 */
	function _getDependencyInjector() : IDependencyInjector
	{
		return this._injector;
	}
	
	#if debug
	/**
	 * Getter for runtime dependencies that needs to be
	 * checked before initialisation end
	 * @return <code>IRuntimeDependencies</code> used by this module
	 */
	function _getRuntimeDependencies() : hex.module.dependency.IRuntimeDependencies
	{
		throw new VirtualMethodException();
	}
	
	/**
	 * Check collection of injected dependencies
	 * @param	dependencies
	 */
	function _checkRuntimeDependencies( dependencies : hex.module.dependency.IRuntimeDependencies ) : Void
	{
		hex.module.dependency.RuntimeDependencyChecker.check( this, this._injector, dependencies );
	}
	#end
	
	/**
	 * Add collection of module configuration classes that 
	 * need to be executed before initialisation's end
	 * @param	configurations
	 */
	function _addStatelessConfigClasses( configurations : Array<Class<IStatelessConfig>> ) : Void
	{
		for ( configurationClass in configurations )
		{
			var config : IStatelessConfig = this._injector.instantiateUnmapped( configurationClass );
			config.configure();
		}
	}
	
	/**
	 * Add collection of runtime configurations that 
	 * need to be executed before initialisation's end
	 * @param	configurations
	 */
	function _addStatefulConfigs( configurations : Array<IStatefulConfig> ) : Void
	{
		for ( configuration in configurations )
		{
			configuration.configure( this._injector, this );
		}
	}
	
	/**
	 * 
	 */
	function _get<T>( type : Class<T>, name : String = '' ) : T
	{
		return this._injector.getInstance( type, name );
	}
	
	/**
	 * 
	 */
	function _map<T>( tInterface : Class<T>, ?tClass : Class<T>,  name : String = "", asSingleton : Bool = false ) : Void
	{
		if ( asSingleton )
		{
			this._injector.mapToSingleton( tInterface, tClass != null ? tClass : tInterface, name );
		}
		else
		{
			this._injector.mapToType( tInterface, tClass != null ? tClass : tInterface, name );
		}
	}
	
	/**
	 * 
	 */
	macro public function _getDependency<T>( ethis : Expr, clazz : ExprOf<Dependency<T>>, ?id : ExprOf<String> ) : ExprOf<T>
	{
		var classRepresentation = InjectorUtil._getStringClassRepresentation( clazz );
		var classReference = InjectorUtil._getClassReference( clazz );
		var ct = InjectorUtil._getComplexType( clazz );
		
		var e = macro @:pos( ethis.pos ) $ethis._injector.getInstanceWithClassName( $v { classRepresentation }, $id );
		return 
		{
			expr: ECheckType
			( 
				e,
				ct
			),
			pos:ethis.pos
		};
	}
}