/*******************************************************************************
 * Copyright (c) 2015 Dell Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Daniel Ford, Dell Corporation - initial API and implementation
 *******************************************************************************/
package com.dell.research.bc.eth.solidity.editor.scoping

import com.dell.research.bc.eth.solidity.editor.solidity.Contract
import com.dell.research.bc.eth.solidity.editor.solidity.ModifierInvocation
import java.util.HashSet
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes
import org.eclipse.xtext.scoping.impl.AbstractDeclarativeScopeProvider

import static extension com.dell.research.bc.eth.solidity.editor.SolidityUtil.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import com.dell.research.bc.eth.solidity.editor.solidity.MorC
import com.dell.research.bc.eth.solidity.editor.solidity.FunctionDefinition

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 *
 */
class SolidityScopeProvider extends AbstractDeclarativeScopeProvider {

	def IScope scope_ModifierInvocation_name(ModifierInvocation modifier, EReference eReference) {
		val c = modifier.getContainerOfType(Contract)
		val f = modifier.getContainerOfType(FunctionDefinition)
		
		val isConstructor = f.name.equals(c.name)
		
		val included = new HashSet<MorC>()
		var allContracts = c.classHierarchy.filter(Contract)
		included.addAll(c.body.modifiers)
		if(isConstructor)
			included.addAll(allContracts)
		allContracts.forEach [
			included.addAll(it.body.modifiers)
		]
		Scopes::scopeFor(included)
	}

}
