/*
 * generated by Xtext 2.12.0
 */
package br.com.kerubin.dsl.mkl.ui

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtext.ui.generator.IDerivedResourceMarkers

/**
 * Use this class to register components to be used within the Eclipse IDE.
 */
@FinalFieldsConstructor
class MklUiModule extends AbstractMklUiModule {
	
	
	def Class<? extends IDerivedResourceMarkers> bindDerivedResourceMarkers() {
		
		return MklDerivedResourceMarkers
		
	}
	
}
