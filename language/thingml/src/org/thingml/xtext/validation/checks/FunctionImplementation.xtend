package org.thingml.xtext.validation.checks

import org.eclipse.emf.common.util.EList
import org.eclipse.xtext.validation.Check
import org.thingml.xtext.constraints.ThingMLHelpers
import org.thingml.xtext.constraints.Types
import org.thingml.xtext.helpers.ActionHelper
import org.thingml.xtext.helpers.TyperHelper
import org.thingml.xtext.thingML.Function
import org.thingml.xtext.thingML.PropertyReference
import org.thingml.xtext.thingML.ReturnAction
import org.thingml.xtext.thingML.Thing
import org.thingml.xtext.thingML.ThingMLPackage
import org.thingml.xtext.thingML.VariableAssignment
import org.thingml.xtext.validation.AbstractThingMLValidator
import org.thingml.xtext.validation.Checker

class FunctionImplementation extends AbstractThingMLValidator {
	Checker checker = new Checker("Generic", this);
	
	@Check(FAST)
	def checkFunction(Function f) {
		if (!f.abstract) { // if function is concrete then we check its implementation
			val refs = ThingMLHelpers.getAllExpressions(ThingMLHelpers.findContainingThing(f), PropertyReference)
			val assigns = ActionHelper.getAllActions(ThingMLHelpers.findContainingThing(f), VariableAssignment) 
			f.parameters.forEach [p, i |	
				//Checks that all params are used			
				val isUsed = refs.exists[pr |
					return pr.property.equals(p)
				]
				if (!isUsed) {
					warning("Parameter " + p.getName() + " is never used", f, ThingMLPackage.eINSTANCE.function_Parameters, i)					
				}		
				//Checks that no param is re-assigned		
				assigns.forEach[va |
					if (va.property.equals(p)) {
						warning("Re-assigning parameter " + p.getName() + " can have side effects", va.eContainer, va.eContainingFeature)		
					}
				]					 							
			]			
			//Checks return type
			if (f.typeRef !== null && f.typeRef.type !== null) {//non-void function
				ActionHelper.getAllActions(f, ReturnAction).forEach[ra |
					val actualType = TyperHelper.getBroadType(f.getTypeRef().getType());
					val returnType = checker.typeChecker.computeTypeOf(ra.getExp());
					val parent = ra.eContainer.eGet(ra.eContainingFeature)
					if (returnType.equals(Types.ERROR_TYPE)) {
						val msg = "Function " + f.getName() + " of Thing " + (f.eContainer as Thing).getName() + " should return " + actualType.getName() + ". Found " + returnType.getName() + ".";						
						if (parent instanceof EList)
							error(msg, ra.eContainer, ra.eContainingFeature, (parent as EList).indexOf(ra))
						else
							error(msg, ra.eContainer, ra.eContainingFeature)
					} else if (returnType.equals(Types.ANY_TYPE)) {
						val msg = "Function " + f.getName() + " of Thing " + (f.eContainer as Thing).getName() + " should return " + actualType.getName() + ". Found " + returnType.getName() + ".";
						if (parent instanceof EList)
							error(msg, ra.eContainer, ra.eContainingFeature, (parent as EList).indexOf(ra))
						else
							error(msg, ra.eContainer, ra.eContainingFeature)
					} else if (!TyperHelper.isA(returnType, actualType)) {
						val msg = "Function " + f.getName() + " of Thing " + (f.eContainer as Thing).getName() + " should return " + actualType.getName() + ". Found " + returnType.getName() + ".";
						if (parent instanceof EList)
							error(msg, ra.eContainer, ra.eContainingFeature, (parent as EList).indexOf(ra))
						else
							error(msg, ra.eContainer, ra.eContainingFeature)
					}
				]
			}
		} else {
			var thing = f.eContainer as Thing
			if (!thing.fragment) {
				error("Thing " + thing.getName() + " is not a fragment, but contains abstract function " + f.getName(), f.eContainer, f.eContainingFeature, thing.functions.indexOf(f))
			}
		}
		
	}
}