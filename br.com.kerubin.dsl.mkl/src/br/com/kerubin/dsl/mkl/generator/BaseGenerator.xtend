package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Configuration
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Service
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractFileSystemAccess
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.OutputConfiguration

abstract class BaseGenerator {
	
	private static val OUTPUT_DIRECTORY = '.'
	protected Resource resource
	protected IFileSystemAccess2 fsa
	protected Service service
	protected Configuration configuration
	protected Iterable<Entity> entities
	private OutputConfiguration outputConfig
	
	new(Resource resource, IFileSystemAccess2 fsa) {
		this.resource = resource
		this.fsa = fsa
		
		service = resource.allContents.filter(Service).head
		configuration = service.configuration
		entities = service.elements.filter(Entity)
	}
	
	def generateFile(String fileName, CharSequence contents) {
		if (outputConfig === null) {
			outputConfig = (fsa as AbstractFileSystemAccess).outputConfigurations.get(IFileSystemAccess.DEFAULT_OUTPUT)
			outputConfig.outputDirectory = OUTPUT_DIRECTORY
		}
		fsa.generateFile(fileName, contents)
	}
	
	abstract def void generate()
	
}