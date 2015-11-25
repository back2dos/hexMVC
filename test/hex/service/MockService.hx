package hex.service;

import hex.service.AbstractService;
import hex.service.ServiceConfiguration;
import hex.service.ServiceEvent;

/**
 * ...
 * @author Francis Bourre
 */
class MockService extends AbstractService<ServiceEvent, ServiceConfiguration>
{
	public function new()
	{
		super();
		this.setEventClass( ServiceEvent );
	}
}