package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import java.util.List

class WebEntityTranslationGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateTranslationKeysForEntities
		generateTranslationService
	}
	
	def getDefaultTranslationFileName() {
		val path = service.webServiceI18nPath
		val fileName = path + I18N_DEF
		fileName 
	}
	
	def generateTranslationKeysForEntities() {
		val fileName = getDefaultTranslationFileName
		generateFile(fileName, doGenerateTranslationKeysForEntities)
	}
	
	def generateTranslationService() {
		val path = service.webServiceI18nPath
		val fileName = path + service.toTranslationServiceName + '.ts'
		generateFile(fileName, doGenerateTranslationService)
	}
	
	def CharSequence doGenerateTranslationKeysForEntities() {
		val List<String> keys = newArrayList
		entities.forEach[it.generateTranslationKeysForEntity(keys)]
		
		'''
		{
			«keys.map[it].join(',\r\n')»
		}
		'''
	}
	
	def void generateTranslationKeysForEntity(Entity entity, List<String> keys) {
		keys.add('"' + entity.translationKey + '": "' + entity.labelValue + '"')
		entity.slots.forEach[
			keys.add('"' + it.translationKey + '": "' + it.labelValue + '"')
		]
	}
	
	def CharSequence doGenerateTranslationService() {
		val fileName = getDefaultTranslationFileName.replace('web/src-gen', 'src')
		
		'''
		import { Injectable } from '@angular/core';
		import { Http } from '@angular/http';
		
		@Injectable()
		export class «service.toTranslationServiceClassName» {
		
		  translations: Object;
		
		  constructor(private http: Http) {
		    this.loadTranslations();
		  }
		
		  loadTranslations() {
		    this.http.get('«fileName»')
		    .toPromise()
		    .then(response => {
		      const data = response.json();
		      this.translations = data;
		    })
		    .catch(error => {
		      console.log(`Error loading translations: ${error}`);
		    });
		  }
		
		  public getTranslation(key: string): string {
		    const translation = this.translations[key];
		    if (translation) {
		      return translation;
		    }
		    return key;
		  }
		
		}
		'''
	}
	
}