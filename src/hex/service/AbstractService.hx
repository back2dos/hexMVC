package hex.service;

import hex.error.VirtualMethodException;
import hex.event.IEvent;
import hex.event.LightweightClosureDispatcher;
import hex.service.ServiceEvent;
import hex.service.ServiceConfiguration;
import hex.service.stateless.StatelessServiceEvent;

/**
 * ...
 * @author Francis Bourre
 */
class AbstractService implements IService
{
	private var _configuration : ServiceConfiguration;
	
	private function new() 
	{
		
	}

	public function getConfiguration() : ServiceConfiguration
	{
		return this._configuration;
	}
	
	@postConstruct
	public function createConfiguration() : Void
	{
		throw new VirtualMethodException( this + ".createConfiguration must be overridden" );
	}
	
	public function setConfiguration( configuration : ServiceConfiguration ) : Void
	{
		throw new VirtualMethodException( this + ".setConfiguration must be overridden" );
	}
	
	public function addHandler( eventType : String, handler : IEvent->Void ) : Void
	{
		throw new VirtualMethodException( this + ".addHandler must be overridden" );
	}
	
	public function removeHandler( eventType : String, handler : IEvent->Void ) : Void
	{
		throw new VirtualMethodException( this + ".removeHandler must be overridden" );
	}
	
	public function release() : Void
	{
		throw new VirtualMethodException( this + ".release must be overridden" );
	}
}