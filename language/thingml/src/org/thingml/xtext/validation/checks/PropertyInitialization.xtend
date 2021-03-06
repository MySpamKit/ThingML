package org.thingml.xtext.validation.checks

import java.util.Set
import org.eclipse.xtext.validation.Check
import org.thingml.xtext.constraints.ThingMLHelpers
import org.thingml.xtext.constraints.Types
import org.thingml.xtext.helpers.TyperHelper
import org.thingml.xtext.thingML.ArrayInit
import org.thingml.xtext.thingML.ConfigPropertyAssign
import org.thingml.xtext.thingML.Configuration
import org.thingml.xtext.thingML.Enumeration
import org.thingml.xtext.thingML.Literal
import org.thingml.xtext.thingML.LocalVariable
import org.thingml.xtext.thingML.Property
import org.thingml.xtext.thingML.PropertyAssign
import org.thingml.xtext.thingML.PropertyReference
import org.thingml.xtext.thingML.Thing
import org.thingml.xtext.thingML.ThingMLModel
import org.thingml.xtext.thingML.ThingMLPackage
import org.thingml.xtext.thingML.TypeRef
import org.thingml.xtext.thingML.UnaryMinus
import org.thingml.xtext.thingML.Variable
import org.thingml.xtext.validation.ThingMLValidatorCheck
import org.thingml.xtext.validation.TypeChecker

class PropertyInitialization extends ThingMLValidatorCheck {
	
	def Set<Property> getUninitializedProperties(Thing t) {
		val props = newHashSet()
		// Properties from current thing
		t.properties.forEach[prop|
			if (prop.init === null)
				props.add(prop);
		]
		
		// Properties from included things
		t.includes.forEach[inc | props.addAll(getUninitializedProperties(inc))]
		
		// Remove properties initialised by set statements
		t.assign.forEach[propAssign|
			props.removeIf(prop | prop === propAssign.property)
		]
		
		return props
	}
	
	@Check(FAST) 
	def checkPropertyAssign(PropertyAssign pa) {
		if (pa.property.typeRef.isIsArray && !(pa.index !== null || pa.init instanceof ArrayInit)) {
			val msg = "Property " + pa.property.name + " is an array, and can only be assigned with an array initialiser, or indexed set statements.";
			error(msg, (pa.eContainer as Thing), ThingMLPackage.eINSTANCE.thing_Assign, (pa.eContainer as Thing).assign.indexOf(pa))
			return;//no need to check more until this is fixed
		}
		if (!pa.property.typeRef.isIsArray && pa.index !== null) {
			val msg = "Property " + pa.property.name + " is not an array."
			error(msg, (pa.eContainer as Thing), ThingMLPackage.eINSTANCE.thing_Assign, (pa.eContainer as Thing).assign.indexOf(pa))
			return;//no need to check more until this is fixed
		}
		val pt = TyperHelper.getBroadType(pa.property.typeRef.type)
		val vt = TypeChecker.computeTypeOf(pa.init)
		if(!TyperHelper.isA(vt, pt)) {
			val msg = "Wrong type. Expected " + pt.name + ". Found " + vt.name
			error(msg, (pa.eContainer as Thing), ThingMLPackage.eINSTANCE.thing_Assign, (pa.eContainer as Thing).assign.indexOf(pa))
		}
		if (pa.index !== null) {
			val indexT = TypeChecker.computeTypeOf(pa.index)
			if(!TyperHelper.isA(indexT, Types.INTEGER_TYPE)) {
			val msg = "Index must be an integer. Found " + indexT.name
			error(msg, (pa.eContainer as Thing), ThingMLPackage.eINSTANCE.thing_Assign, (pa.eContainer as Thing).assign.indexOf(pa))				
			}
		}
	}
	
	@Check(FAST) 
	def checkPropertyAssign(ConfigPropertyAssign pa) {
		if (pa.property.typeRef.isIsArray && !(pa.index !== null || pa.init instanceof ArrayInit)) {
			val msg = "Property " + pa.property.name + " is an array, and can only be assigned with an array initialiser, or indexed set statements.";
			error(msg, (pa.eContainer as Configuration), ThingMLPackage.eINSTANCE.configuration_Propassigns, (pa.eContainer as Configuration).propassigns.indexOf(pa))
			return;//no need to check more until this is fixed
		}
		if (pa.property.typeRef.cardinality === null && pa.index !== null) {
			val msg = "Property " + pa.property.name + " is not an array."
			error(msg, (pa.eContainer as Configuration), ThingMLPackage.eINSTANCE.configuration_Propassigns, (pa.eContainer as Configuration).propassigns.indexOf(pa))
			return;//no need to check more until this is fixed
		}
		val pt = TyperHelper.getBroadType(pa.property.typeRef.type)
		val vt = TypeChecker.computeTypeOf(pa.init)
		if(!TyperHelper.isA(vt, pt)) {
			val msg = "Wrong type. Expected " + pt.name + ". Found " + vt.name
			error(msg, (pa.eContainer as Configuration), ThingMLPackage.eINSTANCE.configuration_Propassigns, (pa.eContainer as Configuration).propassigns.indexOf(pa))
		}
		if (pa.index !== null) {
			val indexT = TypeChecker.computeTypeOf(pa.index)
			if(!TyperHelper.isA(indexT, Types.INTEGER_TYPE)) {
			val msg = "Index must be an integer. Found " + indexT.name
			error(msg, (pa.eContainer as Configuration), ThingMLPackage.eINSTANCE.configuration_Propassigns, (pa.eContainer as Configuration).propassigns.indexOf(pa))				
			}
		}
	}	
	
	@Check(FAST)
	def checkPropertyInitialization(Configuration cfg) {
		cfg.instances.forEach[inst, i|
			val props = getUninitializedProperties(inst.type).filter[p | p.readonly].toSet;
			
			// Remove properties initialised by set statements
			cfg.propassigns.forEach[propAssign|
				props.removeIf(prop | prop === propAssign.property)
			]
			
			if (!props.empty) {
				val msg = props.join("Properties (",", ",") are not initialized")[it.name]
				error(msg, cfg, ThingMLPackage.eINSTANCE.configuration_Instances, i, "properties-not-initialized")
			}
		]
	}
	
	@Check(FAST)
	def checkArray(Variable p) {
		if (p.typeRef.cardinality !== null) {
			if (p.typeRef.cardinality instanceof PropertyReference) {
				val prop = (p.typeRef.cardinality as PropertyReference).property
				var isReadonly = false;
				if (prop instanceof Property) {
					isReadonly = (prop as Property).readonly
				} else if (prop instanceof LocalVariable) {
					isReadonly = (prop as LocalVariable).readonly
				}
				if (!isReadonly) {
					val msg = "Array cardinality must be an integer literal or a read-only property/variable. Variable " + prop.name + " is not read-only."
					error(msg, p, ThingMLPackage.eINSTANCE.namedElement_Name)
				}
				val actualType = TyperHelper.getBroadType(prop.getTypeRef().getType());
				if (!TyperHelper.isA(actualType, Types.INTEGER_TYPE)) {
					val msg = "Array cardinality must resolve to Integer. Property/Variable " + prop.name + " is " + actualType.name + "."
					error(msg, p, ThingMLPackage.eINSTANCE.namedElement_Name)
				}
			}
		}
	}
	
	@Check(FAST)
	def checkEnumInitialization(Enumeration e) {
		if (e.typeRef !== null) {//all literal must be initialized
			if (e.literals.exists[l | l.init === null]) {
				val msg = "Enumeration " + e.name + " is typed. All literals must be initialized."
				error(msg, ThingMLHelpers.findContainingModel(e), ThingMLPackage.eINSTANCE.thingMLModel_Types, (ThingMLHelpers.findContainingModel(e) as ThingMLModel).types.indexOf(e))
			}
			e.literals.forEach[l, i |
				if (l.init !== null) {
					val litType = TypeChecker.computeTypeOf(l.init)
					if(!TyperHelper.isA(litType, e.typeRef.type)) {
						val msg = "Literal " + l.name + " must be of type " + TyperHelper.getBroadType(e.typeRef.type).name + ". Found " + TyperHelper.getBroadType(litType).name
						error(msg, e, ThingMLPackage.eINSTANCE.enumeration_Literals, i)				
					}				
				}
			]
		}
	}	
	
	@Check(FAST)
	def checkArrayInit(ArrayInit ai) {
		ai.values.forEach[e, i |
			var ok = false;
			if (e instanceof Literal) {ok = true;}
			else if (e instanceof PropertyReference) {
				val pr = e as PropertyReference
				if (pr.property instanceof Property) {ok = (pr.property as Property).readonly;}
				else if (pr.property instanceof LocalVariable) {ok = (pr.property as LocalVariable).readonly;}
			} else if (e instanceof UnaryMinus) {
				val um = e as UnaryMinus
				if (um.term instanceof Literal) {ok = true;}
				else if (um.term instanceof PropertyReference) {
					val pr = um.term as PropertyReference
					if (pr.property instanceof Property) {ok = (pr.property as Property).readonly;}
					else if (pr.property instanceof LocalVariable) {ok = (pr.property as LocalVariable).readonly;}
				}
			}
			if (!ok) {
				val msg = "Arrays can only be initialized with literals or references to read-only properties."
				error(msg, ai, ThingMLPackage.eINSTANCE.arrayInit_Values, i)
			} else {//right type of expression, let's check the type
				val et = TypeChecker.computeTypeOf(e)
				val container = ai.eContainer();
				var TypeRef typeref = null
				if (container instanceof Variable) {
					val v = container as Variable
					typeref = v.typeRef					
				}
				else if (container instanceof PropertyAssign) {
					val pa = container as PropertyAssign
					typeref = pa.property.typeRef
				} else if (container instanceof ConfigPropertyAssign) {
					val pa = container as ConfigPropertyAssign
					typeref = pa.property.typeRef					
				}
				val t = TyperHelper.getBroadType(typeref.getType());
				if(!TyperHelper.isA(et, t)) {
					val msg = "Wrong type. Expected " + t.name + ". Found " + et.name
					error(msg, ai, ThingMLPackage.eINSTANCE.arrayInit_Values, i)
				}
			}
		]
	}
}