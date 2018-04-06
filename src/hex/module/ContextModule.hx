package hex.module;

import hex.core.IApplicationContext;
import hex.di.*;
import hex.di.provider.DomainLoggerProvider;
import hex.di.util.InjectorUtil;
import hex.domain.Domain;
import hex.domain.DomainExpert;
import hex.error.IllegalStateException;
import hex.log.ILogger;
import hex.log.LogManager;
import hex.log.message.DomainMessageFactory;
// import hex.metadata.AnnotationProvider;
// import hex.metadata.IAnnotationProvider;
import hex.module.IContextModule;

/**
 * ...
 * @author Francis Bourre
 */
class ContextModule implements IContextModule
{
	var _injector 				: Injector;
	// var _annotationProvider 	: IAnnotationProvider;
	var _logger 				: ILogger;

	public function new()
	{
		this._injector = new Injector();
		this._injector.mapToValue( IBasicInjector, this._injector );
		this._injector.mapToValue( IDependencyInjector, this._injector );

		this._injector.mapToValue( IContextModule, this );
		
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
		if ( !this.isInitialized )
		{
			// this._annotationProvider = AnnotationProvider.getAnnotationProvider( this.getDomain(), null, context );
			// this._annotationProvider.registerInjector( this._injector );
			this._onInitialisation();
			this.isInitialized = true;
		}
		else
		{
			throw new IllegalStateException( "initialize can't be called more than once. Check your code." );
		}
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
	 * Release this module
	 */
	@:final 
	public function release() : Void
	{
		if ( !this.isReleased )
		{
			this.isReleased = true;
			this._onRelease();

			DomainExpert.getInstance().releaseDomain( this );

			// if ( this._annotationProvider != null )
			// {
			// 	this._annotationProvider.unregisterInjector( this._injector );
			// }
			
			this._injector.destroyInstance( this );
			this._injector.teardown();
			
			this._logger = null;
		}
		else
		{
			throw new IllegalStateException( this + ".release can't be called more than once. Check your code." );
		}
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
	
	/**
	 * 
	 */
	function _get<T>( type : ClassRef<T>, ?name : MappingName) : T
	{
		return this._injector.getInstance( type, name );
	}
	
}