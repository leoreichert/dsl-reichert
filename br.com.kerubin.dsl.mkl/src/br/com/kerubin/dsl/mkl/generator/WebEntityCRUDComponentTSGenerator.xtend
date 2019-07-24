package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleWebUtils.*
import br.com.kerubin.dsl.mkl.model.Rule
import java.util.Set
import java.util.LinkedHashSet
import br.com.kerubin.dsl.mkl.model.RuleTargetField

class WebEntityCRUDComponentTSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	StringConcatenationExt imports
	val LinkedHashSet<String> importsSet = newLinkedHashSet
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateComponent]
	}
	
	def generateComponent(Entity entity) {
		val path = entity.webEntityPath
		val entityFile = path + entity.toEntityWebCRUDComponentName + '.ts'
		generateFile(entityFile, entity.doGenerateEntityTSComponent)
	}
	
	def CharSequence doGenerateEntityTSComponent(Entity entity) {
		imports = new StringConcatenationExt()
		entity.initializeImports()
		
		val webName = entity.toWebName
		val dtoName = entity.toDtoName
		val fieldName = entity.fieldName
		val serviceName = entity.toEntityWebServiceClassName
		val serviceVar = serviceName.toFirstLower
		val ruleMakeCopies = entity.ruleMakeCopies
		val rulesFormOnCreate = entity.rulesFormOnCreate
		val rulesFormOnUpdate = entity.rulesFormOnUpdate
		val rulesFormOnInit = entity.rulesFormOnInit
		val ruleFormActionsWithFunction = entity.ruleFormActionsWithFunction
		val rulesWithSlotAppyStyleClass = entity.rulesWithSlotAppyStyleClass
		val rulesFormWithDisableCUD = entity.getRulesFormWithDisableCUD
		
		val hasCalendar = entity.hasDate
		
		imports.add('''import { �dtoName� } from './�entity.toEntityWebModelName�';''')
		imports.add('''import { �serviceName� } from './�webName�.service';''')
		imports.add('''import { �service.toTranslationServiceClassName� } from '�service.serviceWebTranslationComponentPathName�';''')
		if (entity.hasDate || entity.fieldsAsEntityHasDate) {
			imports.add('''import * as moment from 'moment';''')
		}
		entity.slots.filter[it.isEntity].forEach[ 
			val slotAsEntity = it.asEntity
			imports.newLine
			
			if (slotAsEntity.isNotSameName(entity)) { // Is not a field of same type of mine entity
				imports.add('''import { �slotAsEntity.toEntityWebServiceClassName� } from './�slotAsEntity.toEntityWebServiceNameWithPath�';''')
				imports.add('''import { �slotAsEntity.toDtoName� } from './�slotAsEntity.toEntityWebModelNameWithPah�';''')
			}
			imports.add('''import { �slotAsEntity.toAutoCompleteName� } from './�slotAsEntity.toEntityWebModelNameWithPah�';''')
		]
		entity.slots.filter[it.isEnum].forEach[
			val slotAsEnum = it.asEnum
			imports.newLine
			imports.add('''import { �slotAsEnum.toDtoName� } from '�service.serviceWebEnumsPathName�';''')
		]
		
		if (!ruleMakeCopies.empty) {
			imports.add('''import {SelectItem} from 'primeng/api';''')
		}

		imports.add('''import { MessageHandlerService } from 'src/app/core/message-handler.service';''')
		
		/*if (entity.hasPassword) {
			imports.add('''import {PasswordModule} from 'primeng/password';''')
		}*/
		
		val component = entity.toEntityWebCRUDComponentName
		val body = '''
		
		@Component({
		  selector: 'app-�component�',
		  templateUrl: './�component�.html',
		  styleUrls: ['./�component�.css']
		})
		
		export class �entity.toEntityWebComponentClassName� implements OnInit {
			�IF hasCalendar�
			
			�getCalendarLocaleSettingsVarName�: any;
			
			�ENDIF�
			�IF !ruleMakeCopies.empty��initializeMakeCopiesVars(ruleMakeCopies.head)��ENDIF�
			�fieldName� = new �dtoName�();
			�entity.slots.filter[isEntity].map[mountAutoCompleteSuggestionsVar].join('\n\r')�
			�entity.slots.filter[isEnum].map[mountDropdownOptionsVar].join('\n\r')�
			�IF entity.isEnableReplication��entity.entityReplicationQuantity� = 1;�ENDIF�
			
			constructor(
			    private �serviceVar�: �serviceName�,
			    private �service.toTranslationServiceVarName�: �service.toTranslationServiceClassName�,
			    �entity.slots.filter[isEntity && it.asEntity.isNotSameName(entity)].map[mountServiceConstructorInject].join('\n\r')�
			    private route: ActivatedRoute,
			    private messageHandler: MessageHandlerService
			) { 
				�entity.slots.filter[isEnum].map['''this.�it.webDropdownOptionsInitializationMethod�();'''].join('\n\r')�
				�IF !ruleMakeCopies.empty�
				this.initializeCopiesReferenceFieldOptions();
				�ENDIF�
			}
			
			ngOnInit() {
				�IF hasCalendar�
				this.initLocaleSettings();
				�ENDIF�
				�IF !rulesFormOnInit.empty�
				this.rulesOnInit();
				
				�ENDIF�
				�IF !rulesFormOnCreate.empty�
				this.rulesOnCreate();
				
				�ENDIF�
				�IF entity.hasEnumSlotsWithDefault�
				this.initializeEnumFieldsWithDefault();
				�ENDIF�
			    const id = this.route.snapshot.params['id'];
			    if (id) {
			      this.get�dtoName�ById(id);
			    }
			}
			
			begin(form: FormControl) {
			    form.reset();
			    setTimeout(function() {
			      this.�fieldName� = new �dtoName�();
			      �IF !rulesFormOnInit.empty�
			      this.rulesOnInit();
	  			  �ENDIF�
			      �IF entity.hasEnumSlotsWithDefault�
			      this.initializeEnumFieldsWithDefault();
			      �ENDIF�
			    }.bind(this), 1);
			}
			
			validateAllFormFields(form: FormGroup) {
			    Object.keys(form.controls).forEach(field => {
			      const control = form.get(field);
			
			      if (control instanceof FormControl) {
			        control.markAsDirty({ onlySelf: true });
			      } else if (control instanceof FormGroup) {
			        this.validateAllFormFields(control);
			      }
			    });
			}
			
			save(form: FormGroup) {
				if (!form.valid) {
			      this.validateAllFormFields(form);
			      return;
			    }
				    
			    if (this.isEditing) {
			      this.update();
			    } else {
			      this.create();
			    }
				�IF !ruleMakeCopies.empty�
				this.initializeCopiesReferenceFieldOptions();
				�ENDIF�
			}
			
			create() {
				�IF !rulesFormOnCreate.empty�
				this.rulesOnCreate();
				�ENDIF�
				
			    this.�serviceVar�.create(this.�fieldName�)
			    .then((�fieldName�) => {
			      this.�fieldName� = �fieldName�;
			      this.messageHandler.showSuccess('Registro criado com sucesso!');
			    }).
			    catch(error => {
			      this.messageHandler.showError(error);
			    });
			}
			
			update() {
				�IF !rulesFormOnUpdate.empty�
				this.rulesOnUpdate();
				
				�ENDIF�
			    this.�serviceVar�.update(this.�fieldName�)
			    .then((�fieldName�) => {
			      this.�fieldName� = �fieldName�;
			      this.messageHandler.showSuccess('Registro alterado!');
			    })
			    .catch(error => {
			      this.messageHandler.showError(error);
			    });
			}
			
			get�dtoName�ById(id: string) {
			    this.�serviceVar�.retrieve(id)
			    .then((�fieldName�) => this.�fieldName� = �fieldName�)
			    .catch(error => {
			      this.messageHandler.showError(error);
			    });
			}
			
			get isEditing() {
			    return Boolean(this.�fieldName�.id);
			}
			
			�IF entity.hasEnumSlotsWithDefault�
			�entity.initializeEnumSlotsWithDefault�
			�ENDIF�
			
			�IF entity.isEnableReplication�
			
			replicar�dtoName�() {
			    this.�serviceVar�.replicar�dtoName�(this.�fieldName�.id, this.�fieldName�.agrupador, this.�entity.entityReplicationQuantity�)
			    .then((result) => {
			      if (result === true) {
			        this.messageHandler.showSuccess('Os registros foram criados com sucesso.');
			      } else {
			        this.messageHandler.showError('N�o foi poss�vel criar os registros.');
			      }
			    })
			    .catch(error => {
			      this.messageHandler.showError(error);
			    });
			  }
			�ENDIF�
			
			�entity.slots.filter[isEntity].map[mountAutoComplete].join('\n\r')�
			
			�entity.slots.filter[isEnum].map[it.generateEnumInitializationOptions].join�
			
			�buildTranslationMethod(service)�
			
			�ruleMakeCopies.map[generateRuleMakeCopiesActions].join�
			�ruleMakeCopies.map[generateInitializeCopiesReferenceFieldOptions].join�
			�ruleFormActionsWithFunction.map[generateRuleFormActionsWithFunction].join�
			�IF !rulesFormOnInit.empty�
			rulesOnInit() {
				�rulesFormOnInit.map[it.generateRuleFormOnInit(entity.fieldName, importsSet)].join�
			}
			
			�ENDIF�
			�IF !rulesFormOnCreate.empty�
			rulesOnCreate() {
				�rulesFormOnCreate.map[it.generateRuleFormOnCreate(entity.fieldName, importsSet)].join�
			}
			
			�ENDIF�
			�IF !rulesFormOnUpdate.empty�
			rulesOnUpdate() {
				�rulesFormOnUpdate.map[it.generateRuleFormOnUpdate(entity.fieldName, importsSet)].join�
			}
			
			�ENDIF�
			
			�IF !rulesWithSlotAppyStyleClass.empty�
												
			// Begin RuleWithSlotAppyStyleClass 
			�rulesWithSlotAppyStyleClass.map[it.generateRuleWithSlotAppyStyleClass].join�
			// End Begin RuleWithSlotAppyStyleClass
			�ENDIF�
			
			�IF !rulesFormWithDisableCUD.empty�
			�rulesFormWithDisableCUD.head.generateRuleFormWithDisableCUD�
			�ENDIF�
			�IF hasCalendar�
			�generateInitLocaleSettings�
			�ENDIF�
		}
		'''
		
		val source = imports.ln.toString /*+ importsSet.join('\r\n')*/ + '\r\n' + body
		source
	}
	
	def CharSequence generateInitLocaleSettings() {
		'''
		
		initLocaleSettings() {
			this.�getCalendarLocaleSettingsVarName� = this.�service.toTranslationServiceVarName�.�getCalendarLocaleSettingsMethodName�();
		}
		
		'''
	}
	
	def CharSequence generateRuleFormWithDisableCUD(Rule rule) {
		val entity = rule.ruleOwnerEntity
		val methodName = entity.toRuleFormWithDisableCUDMethodName
		
		val hasWhen = rule.hasWhen
		var String expression = 'false'
		if (hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenExpression(resultStrExp)
			expression = resultStrExp.toString
		}
		
		
		'''
		�methodName�() {
			const expression = �expression�;
			return expression;
			
		}
		'''
	}
	
	def CharSequence generateRuleWithSlotAppyStyleClass(Rule rule) {
		val slot = (rule.target as RuleTargetField).target.field
		val methodName = slot.toRuleWithSlotAppyStyleClassMethodName
		
		val hasWhen = rule.hasWhen
		var String expression = 'false'
		if (hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenExpression(resultStrExp)
			expression = resultStrExp.toString
		}
		
		val styleClass = rule.apply.getResutValue
		
		'''
		�methodName�() {
			const expression = �expression�;
			if (expression) {
				return '�styleClass�';
			} else {
				return '';
			}
			
		}
		'''
	}
	
	def CharSequence generateRuleFormActionsWithFunction(Rule rule) {
		val entity = (rule.owner as Entity)
		val function = rule.apply.ruleFunction
		val methodName = entity.toEntityRuleFormActionsFunctionName(function)
		
		val fieldName = entity.fieldName
		val serviceName = entity.toEntityWebServiceClassName
		val serviceVar = serviceName.toFirstLower
		
		val ruleAction = rule.action
		val actionName = ruleAction.toRuleActionName(methodName + '_action')
		val ruleActionWhenConditionName = actionName.toRuleActionWhenConditionName
		
		val hasWhen = rule.hasWhen
		var String expression = null
		if (hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenForGridRowStyleClass(resultStrExp)
			expression = resultStrExp.toString
		}
		
		'''
		�ruleActionWhenConditionName�(): boolean {
			�IF hasWhen�		    
			return �expression�;
			�ELSE�
			return true;
			�ENDIF�
		}
		  
		�actionName�() {
			this.�methodName�();
		}
		
		�methodName�() {
		    this.�serviceVar�.�methodName�(this.�fieldName�)
		    .then((�fieldName�) => {
		      if (�fieldName�) { // Can be null
		      	this.�fieldName� = �fieldName�;
		      }
		      this.messageHandler.showSuccess('Opera��o executada com sucesso.');
		    })
		    .catch(error => {
		      this.messageHandler.showError(error);
		    });
		}
		
		'''
	}
	
	def CharSequence generateRuleFormOnInit(Rule rule, String targetObject, Set<String> imports) {
		'''
		�rule.apply.buildRuleApplyForWeb(targetObject, imports)�
		'''
	}
	
	def CharSequence generateRuleFormOnCreate(Rule rule, String targetObject, Set<String> imports) {
		'''
		�rule.apply.buildRuleApplyForWeb(targetObject, imports)�
		'''
	}
	
	def CharSequence generateRuleFormOnUpdate(Rule rule, String targetObject, Set<String> imports) {
		'''
		�rule.apply.buildRuleApplyForWeb(targetObject, imports)�
		'''
	}
	
	
	
	def CharSequence generateInitializeCopiesReferenceFieldOptions(Rule rule) {
		'''
		 
		initializeCopiesReferenceFieldOptions() {
		    this.copiesReferenceFieldOptions = [
		      this.copiesReferenceField
		    ];
		
		    this.copiesReferenceFieldSelected = this.copiesReferenceField;
		    
		    this.numberOfCopies = 1;
		    this.copiesReferenceFieldInterval = 30;
		}
		'''
	}
	
	
	def CharSequence initializeEnumSlotsWithDefault(Entity entity) {
		'''
		initializeEnumFieldsWithDefault() {
			�entity.slots.filter[isEnum].map[it.initializeSelectedDropDownItem].join�
		}
		'''
	}
	
	def CharSequence initializeSelectedDropDownItem(Slot slot) {
		val enumerarion = slot.asEnum
		var index = -1;
		if (enumerarion.hasDefault) {
			index = enumerarion.defaultIndex
		}
		
		if (index == -1) {
			return ''
		}
		
		'''
		this.�slot.ownerEntity.fieldName�.�slot.fieldName� = this.�slot.webDropdownOptions�[�index�].value;
		'''
		
	}
	
	def CharSequence generateRuleMakeCopiesActions(Rule rule) {
		val actionName = rule.getRuleActionMakeCopiesName
		val entity = (rule.owner as Entity)
		val entityVar = entity.fieldName
		val grouperField = rule.ruleMakeCopiesGrouperSlot
		val serviceName = entity.toEntityWebServiceClassName
		val serviceVar = serviceName.toFirstLower
		
		'''
		
		�actionName�(form: FormControl) {
		      if (!this.�entityVar�.�grouperField.fieldName�) {
		        // this.copiesMustHaveGroup = true;
		        this.messageHandler.showError('Campo \'�grouperField.fieldName.toFirstUpper�\' deve ser informado para gerar c�pias.');
		        return;
		      }
		      // this.copiesMustHaveGroup = false;
		
		      this.�serviceVar�.�actionName�(this.�entityVar�.�entity.id.fieldName�, this.numberOfCopies,
		        this.copiesReferenceFieldInterval, this.�entityVar�.�grouperField.fieldName�)
			    .then(() => {
		        // this.copiesMustHaveGroup = false;
		        this.messageHandler.showSuccess('Opera��o realizada com sucesso!');
			    }).
			    catch(error => {
		        // this.copiesMustHaveGroup = false;
		        const message =  JSON.parse(error._body).message || 'N�o foi poss�vel realizar a opera��o';
		        console.log(error);
			      this.messageHandler.showError(message);
			    });
		}
		'''
	}
	
	def CharSequence initializeMakeCopiesVars(Rule rule) {
		val referenceField = rule.apply.makeCopiesExpression.referenceField.field
		'''
		 
		numberOfCopies = 1;
		copiesReferenceFieldInterval = 30;
		
		copiesReferenceFieldOptions: SelectItem[];
		copiesReferenceField: SelectItem = { label: '�referenceField.labelValue�', value: '�referenceField.fieldName�' };
		copiesReferenceFieldSelected: SelectItem;
		 
		'''
	}
	
	def CharSequence generateEnumInitializationOptions(Slot slot) {
		val enumerarion = slot.asEnum
		'''
		private �slot.webDropdownOptionsInitializationMethod�() {
		    this.�slot.webDropdownOptions� = [
		    	�enumerarion.items.map['''{ label: this.getTranslation('�slot.translationKey + '_' + it.name.toLowerCase�'), value: '�it.name�' }'''].join(', \r\n')�
		    ];
		}
		  
		'''
	}
	
	def CharSequence mountDropdownOptionsVar(Slot slot) {
		val enumerarion = slot.asEnum
		'''
		�slot.webDropdownOptions�: �enumerarion.toDtoName�[];
		'''
	}
	
	def CharSequence mountAutoCompleteSuggestionsVar(Slot slot) {
		val entity = slot.asEntity
		'''
		�slot.webAutoCompleteSuggestions�: �entity.toAutoCompleteName�[];
		'''
	}
	
	def CharSequence mountAutoComplete(Slot slot) {
		val entity = slot.asEntity
		val ownerEntity = slot.ownerEntity
		
		val serviceName = ownerEntity.toEntityWebServiceClassName.toFirstLower
		
		var resultSlots = entity.slots.filter[it.autoCompleteResult && it !== entity.id && !(entity.enableVersion && it.name.toLowerCase == 'version')]
		if (resultSlots.isEmpty) {
			resultSlots = entity.slots.filter[it.autoCompleteResult]
		}
		
		val hasAutoCompleteWithOwnerParams = slot.isAutoCompleteWithOwnerParams
		
		'''
		�slot.toAutoCompleteClearMethodName�(event) {
			// The autoComplete value has been reseted
			this.�ownerEntity.fieldName�.�slot.fieldName� = null;
		}
		
		�slot.toAutoCompleteOnBlurMethodName�(event) {
			// Seems a PrimeNG bug, if clear an autocomplete field, on onBlur event, the null value is empty string.
			// Until PrimeNG version: 7.1.3.
			if (String(this.�ownerEntity.fieldName�.�slot.fieldName�) === '') {
				this.�ownerEntity.fieldName�.�slot.fieldName� = null;
			}
		}
		
		�slot.toAutoCompleteName�(event) {
			�IF hasAutoCompleteWithOwnerParams�
			const �ownerEntity.fieldName� = (JSON.parse(JSON.stringify(this.�ownerEntity.fieldName�)));
			if (String(�ownerEntity.fieldName�.�slot.fieldName� === '')) {
				�ownerEntity.fieldName�.�slot.fieldName� = null;
			}
			�ENDIF�
		    const query = event.query;
		    this.�serviceName�
		      .�slot.toSlotAutoCompleteName�(query�IF hasAutoCompleteWithOwnerParams�, �ownerEntity.fieldName��ENDIF�)
		      .then((result) => {
		        this.�slot.webAutoCompleteSuggestions� = result as �entity.toAutoCompleteName�[];
		      })
		      .catch(error => {
		        this.messageHandler.showError(error);
		      });
		}
		
		�IF !resultSlots.isEmpty�
		�slot.webAutoCompleteFieldConverter�(�slot.fieldName�: �entity.toAutoCompleteName�) {
			let text = '';
			if (�slot.fieldName�) {
				�resultSlots.map[slot.resolveAutocompleteFieldNameForWeb(it).buildAutoCompleteFieldConverter(slot.getAutocompleteFieldNameForWeb(it))].join()�
			}
			
			if (text === '') {
				text = null;
			}
			return text;
		}
		�ENDIF�
		'''
	}
	
	def CharSequence buildAutoCompleteFieldConverter(String resolvedFieldName, String fieldName) {
		'''
		if (�fieldName�) {
		    if (text !== '') {
		      text += ' - ';
		    }
		    text += �resolvedFieldName�; 
		}
		
		'''
	}
	
	def CharSequence mountServiceConstructorInject(Slot slot) {
		val serviceName = slot.asEntity.toEntityWebServiceClassName
		'''
		private �serviceName.toFirstLower�: �serviceName�,
		'''
	}
	
	def void initializeImports(Entity entity) {
		imports.add('''
		import { Component, OnInit } from '@angular/core';
		import { FormControl, FormGroup } from '@angular/forms';
		import { ActivatedRoute, Router } from '@angular/router';
		import {MessageService} from 'primeng/api';
		''')
	}
	
	
}