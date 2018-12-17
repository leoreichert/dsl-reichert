package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class WebEntityModelGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateEntityModel]
	}
	
	def generateEntityModel(Entity entity) {
		val entityDir = entity.webEntityPath
		val entityFile = entityDir + entity.toEntityWebModelName + '.ts'
		generateFile(entityFile, entity.doGenerateEntityModel)
	}
	
	
	def CharSequence doGenerateEntityModel(Entity entity) {
		entity.initializeEntityImports
		
		val body = '''
		�generateSortFieldModel�
		�generatePaginationFilterModel�
		�IF entity.hasListFilterMany�
		�entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoCompleteModel].join�
		�ENDIF�
		�entity.generateEntityListFilterModel�
		�entity.generateEntityDTOModel�
		�entity.generateEntityDefaultAutoComplete�
		'''
		
		val imports = '''
		�entity.imports.map[it].join('\r\n')�
		'''
		
		imports + body 
	}
	
	def CharSequence generateEntityDefaultAutoComplete(Entity entity) {
		val autoCompleteSlots = entity.slots.filter[isAutoCompleteResult]
		'''
		
		export class �entity.toAutoCompleteName� {
			�autoCompleteSlots.map[generateField(entity)].join�
		}
		'''
	}
	
	def CharSequence generateListFilterAutoCompleteModel(Slot slot) {
		val autoComplateName = slot.toAutoCompleteClassName
		
		'''
		
		export class �autoComplateName� {
			�slot.fieldName�: �slot.toWebType�;
		}
		'''
	}
	
	// Begin DTO Model
	def CharSequence generateEntityDTOModel(Entity entity) {
		'''
		
		export class �entity.toEntityDTOName� {
			�entity.generateFields�
		}
		'''
	}
	
	
	def CharSequence generateFields(Entity entity) {
		'''
		�entity.slots.map[generateField(entity)].join�
		'''
		
	}
	
	def CharSequence generateField(Slot slot, Entity entity) {
		var dtoModel = entity.toEntityWebModelNameWithPah(slot)
		
		if (slot.isDTOFull) {
			entity.addImport("import { " + slot.asEntity.toEntityDTOName + " } from './" + dtoModel + "';")
		}
		//else if (slot.isDTOLookupResult) {
		else if (slot.isEntity) {
			entity.addImport("import { " + slot.asEntity.toEntityDTOName + " } from './" + dtoModel + "';")
		}
		else if (slot.isEnum) { 
			entity.addImport("import { " + slot.asEnum.name.toFirstUpper + " } from './" + dtoModel + "';")
			// entity.addImport('import ' + slot.asEnum.enumPackage + ';')
		}
		
		'''
		�IF slot.isEntity�
		�slot.fieldName�: �slot.asEntity.toEntityDTOName�;
		�ELSE�
		�slot.fieldName�: �slot.toWebType�;
		�ENDIF�
		'''
	}
	
	def CharSequence generateGetters(Entity entity) {
		'''
		
		�entity.slots.map[generateGetter].join('\r\n')�
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		
		'''
		�IF slot.isToMany�
		get �slot.fieldName�(): �slot.toWebTypeDTO�[] {
		�ELSE�
		get �slot.fieldName�(): �slot.toWebTypeDTO� {
		�ENDIF�
			return this.�slot.fieldNameWeb�;
		}
		'''
	}
	
	def CharSequence generateSetters(Entity entity) {
		'''
		
		�entity.slots.map[generateSetter].join('\r\n')�
		'''
	}
	
	def CharSequence generateSetter(Slot slot) {
		
		'''
		�IF slot.many && slot.isToMany�
		set �slot.fieldName�(value: �slot.toWebTypeDTO�[]) {
		�ELSE�
		set �slot.fieldName�(value: �slot.toWebTypeDTO�) {
		�ENDIF�
			this.�slot.fieldName� = value;
		}
		'''
	}
	
	def void initializeEntityImports(Entity entity) {
		entity.imports.clear
	}
	
	def CharSequence getSlotsEntityImports(Entity entity) {
		'''
		�entity.slots.filter[it.isEntity].map[it | 
			val slotEntity = it.asEntity
			return "import " + slotEntity.package + "." + slotEntity.toEntityName + ";"
			].join('\r\n')�
		'''
	}
	
	// End DTO entity model
	
	// End DTO entity model
	
	def CharSequence generateSortFieldModel() {
		'''
		
		export class SortField {
		  field: string;
		  order: number;
		
		  constructor(field: string, order: number) {
		    this.field = field;
		    this.order = order = 0;
		  }
		}
		'''
	}
	
	def CharSequence generatePaginationFilterModel() {
		'''
		
		export class PaginationFilter {
		  pageNumber: number;
		  pageSize: number;
		  sortField: SortField;
		
		  constructor() {
		    this.pageNumber = 0;
		    this.pageSize = 10;
		  }
		}
		'''
	}
	
	def CharSequence generateEntityListFilterModel(Entity entity) {
		'''
		
		export class �entity.toEntityListFilterClassName� extends PaginationFilter {
			�entity.generateListFilterFields�
		}
		'''
	}
	
	def CharSequence generateListFilterFields(Entity entity) {
		val slots = entity.slots.filter[it.hasListFilter]
		
		'''
		
		�slots.map[generateListFilterField].join('\r\n')�
		'''
	}
	
	def CharSequence generateListFilterField(Slot slot) {
		var fieldName = slot.fieldName
		
		val isNotNull = slot.isNotNull
			
		val isNull = slot.isNull
		
		val isMany = slot.isListFilterMany
		
		val isBetween = slot.isBetween 
		
		'''
		�IF isMany�
		�fieldName�: �slot.toAutoCompleteClassName�[];
		�ELSEIF isNotNull && isNull�
		�slot.isNotNullFieldName�: boolean;
		�slot.isNullFieldName�: boolean;
		�ELSEIF isNotNull�
		�slot.isNotNullFieldName�: boolean;
		�ELSEIF isNull�
		�slot.isNullFieldName�: boolean;
		�ELSEIF isBetween�
		�slot.toIsBetweenFromName�: �slot.toWebType�;
		�slot.toIsBetweenToName�: �slot.toWebType�;
		�ENDIF�
		'''
	}
	
}