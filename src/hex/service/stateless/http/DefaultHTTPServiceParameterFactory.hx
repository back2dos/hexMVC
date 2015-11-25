package hex.service.stateless.http;
import hex.service.stateless.http.HTTPServiceParameters;
import haxe.Http;

/**
 * ...
 * @author Francis Bourre
 */
class DefaultHTTPServiceParameterFactory implements IHTTPServiceParameterFactory
{
	public function new() 
	{
		
	}

	public function setParameters( httpRequest : Http, parameters : HTTPServiceParameters, ?excludedParameters : Array<String> ) : Http 
	{
		return httpRequest;
	}
}