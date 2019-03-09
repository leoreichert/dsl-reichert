package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Slot

class JavaEntityServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[it |
			generateServiceInterface
			generateServiceInterfaceImpl
		]
	}
	
	def generateServiceInterface(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toServiceName + '.java'
		generateFile(fileName, entity.generateEntityServiceInterface)
	}
	
	def generateServiceInterfaceImpl(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toServiceImplName + '.java'
		generateFile(fileName, entity.generateEntityServiceInterfaceImpl)
	}
	
	def CharSequence generateEntityServiceInterface(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		
		'''
		package �entity.package�;
		
		import org.springframework.data.domain.Page;
		import org.springframework.data.domain.Pageable;
		
		�IF entity.hasAutoComplete�
		import java.util.Collection;
		�ENDIF�
		
		public interface �entity.toServiceName� {
			
			public �entityName� create(�entityName� �entityVar�);
			
			public �entityName� read(�idType� �idVar�);
			
			public �entityName� update(�idType� �idVar�, �entityName� �entityVar�);
			
			public void delete(�idType� �idVar�);
			
			public Page<�entityName�> list(�entity.toEntityListFilterName� �entity.toEntityListFilterName.toFirstLower�, Pageable pageable);
			
			�IF entity.hasAutoComplete�
			public Collection<�entity.toAutoCompleteName�> autoComplete(String query);
			�ENDIF�
			�IF entity.hasListFilterMany�
			�entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoComplete].join�
			�ENDIF�
		}
		'''
	}
	
	def CharSequence generateListFilterAutoComplete(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		'''
		
		public Collection<�autoComplateName.toFirstUpper�> �autoComplateName�(String query);
		'''
	}
	
	def CharSequence generateEntityServiceInterfaceImpl(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOName = entity.toEntityDTOName
		val repositoryVar = entity.toRepositoryName.toFirstLower
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val getEntityMethod = 'get' + entityName
		val publishSlots = entity.getPublishSlots
		val entityEventName = entity.toEntityEventName
		
		'''
		package �entity.package�;
		
		import org.springframework.beans.BeanUtils;
		import org.springframework.beans.factory.annotation.Autowired;
		import org.springframework.data.domain.Page;
		import org.springframework.data.domain.Pageable;
		import org.springframework.stereotype.Service;
		import org.springframework.transaction.annotation.Transactional;
		
		import com.querydsl.core.types.Predicate;
		
		import java.util.Optional;
		�IF entity.hasAutoComplete�
		import java.util.Collection;
		�ENDIF�
		�IF entity.hasPublishEntityEvents�
		import br.com.kerubin.api.messaging.core.DomainEntityEventsPublisher;
		import br.com.kerubin.api.messaging.core.DomainEvent;
		import br.com.kerubin.api.messaging.core.DomainEventEnvelope;
		import br.com.kerubin.api.messaging.core.DomainEventEnvelopeBuilder;
		�service.getImportServiceConstants�
		�ENDIF�
		
		@Transactional
		@Service
		public class �entity.toServiceImplName� implements �entity.toServiceName� {
			
			@Autowired
			private �entity.toRepositoryName� �repositoryVar�;
			
			@Autowired
			private �entity.toEntityListFilterPredicateName� �entity.toEntityListFilterPredicateName.toFirstLower�;
			
			�IF entity.hasPublishEntityEvents�
			@Autowired
			DomainEntityEventsPublisher publisher;
			�ENDIF�
			
			public �entityName� create(�entityName� �entityVar�) {
				�IF !entity.hasPublishCreated�
				return �repositoryVar�.save(�entityVar�);
				�ELSE�
				�entityName� entity = �repositoryVar�.save(�entityVar�);
				publishEvent(entity, �entityEventName�.�entity.toEntityEventConstantName('created')�);
				return entity;
				�ENDIF�
			}
			
			public �entityName� read(�idType� �idVar�) {
				return �getEntityMethod�(�idVar�);
			}
			
			public �entityName� update(�idType� �idVar�, �entityName� �entityVar�) {
				�entityName� entity = �getEntityMethod�(�idVar�);
				BeanUtils.copyProperties(�entityVar�, entity, "�entity.id.name�");
				entity = �repositoryVar�.save(entity);
				
				�IF entity.hasPublishUpdated�
				publishEvent(entity, �entityEventName�.�entity.toEntityEventConstantName('updated')�);
				
				�ENDIF�
				return entity;
			}
			
			public void delete(�idType� �idVar�) {
				�repositoryVar�.deleteById(�idVar�);
				
				�IF entity.hasPublishDeleted�
				�entityName� entity = new �entityName�();
				�entity.id.buildMethodSet('entity', idVar)�;
				publishEvent(entity, �entityEventName�.�entity.toEntityEventConstantName('deleted')�);
				�ENDIF�
			}
			
			�IF entity.hasPublishEntityEvents�
			private void publishEvent(�entityName� entity, String eventName) {
				�entity.toEntityDomainEventTypeName� event = new �entityEventName�(�publishSlots.map[it.buildSlotGet].join(', ')�);
				DomainEventEnvelope<DomainEvent> envelope = DomainEventEnvelopeBuilder
						.getBuilder(eventName, event)
						.domain(�service.toServiceConstantsName�.DOMAIN)
						.service(�service.toServiceConstantsName�.SERVICE)
						.build();
				
				publisher.publish(envelope);
			}
			�ENDIF�
			
			public Page<�entityName�> list(�entity.toEntityListFilterName� �entity.toEntityListFilterName.toFirstLower�, Pageable pageable) {
				Predicate predicate = �entity.toEntityListFilterPredicateName.toFirstLower�.mountAndGetPredicate(�entity.toEntityListFilterName.toFirstLower�);
				
				Page<�entityName�> resultPage = �repositoryVar�.findAll(predicate, pageable);
				return resultPage;
			}
			
			private �entityName� �getEntityMethod�(�idType� �entity.id.name�) {
				Optional<�entityName�> �entityVar� = �repositoryVar�.findById(�idVar�);
				if (!�entityVar�.isPresent()) {
					throw new IllegalArgumentException("�entityDTOName� not found:" + �idVar�.toString());
				}
				return �entityVar�.get();
			}
			
			�IF entity.hasAutoComplete�
			public Collection<�entity.toAutoCompleteName�> autoComplete(String query) {
				Collection<�entity.toAutoCompleteName�> result = �repositoryVar�.autoComplete(query);
				return result;
			}
			�ENDIF�
			�IF entity.hasListFilterMany�
			�entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoCompleteImpl].join�
			�ENDIF�
		}
		'''
	}
	
	def CharSequence buildPublishEvent(Entity entity, String eventName) {
		val publishSlots = entity.getPublishSlots
		val entityEventName = entity.toEntityEventName
		'''
		�entity.toEntityDomainEventTypeName� event = new �entityEventName�(�publishSlots.map[it.buildSlotGet].join(', ')�);
		DomainEventEnvelope<DomainEvent> envelope = DomainEventEnvelopeBuilder
				.getBuilder(�entityEventName�.�entity.toEntityEventConstantName('created')�, event)
				.domain(�service.toServiceConstantsName�.DOMAIN)
				.service(�service.toServiceConstantsName�.SERVICE)
				.build();
		
		publisher.publish(envelope);
		'''
	}
	
	def CharSequence buildSlotGet(Slot slot) {
		var result = ''
		if (slot.isEntity)
			result = 'entity'.buildMethodGetEntityId(slot)
		else
			result = 'entity'.buildMethodGet(slot)
		result
	}
	
	def CharSequence generateListFilterAutoCompleteImpl(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		val repositoryVar = slot.ownerEntity.toRepositoryName.toFirstLower
		
		'''
		
		public Collection<�autoComplateName.toFirstUpper�> �autoComplateName�(String query) {
			Collection<�autoComplateName.toFirstUpper�> result = �repositoryVar�.�autoComplateName�(query);
			return result;
		}
		'''
	}
	
}