/*******************************************************************************
 * Copyright (c) 2015 Dell Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors:
 *     Daniel Ford, Dell Corporation - initial API and implementation
 * 	   Urs Zeidler
 *******************************************************************************/
package com.dell.research.bc.eth.solidity.editor

import com.dell.research.bc.eth.solidity.editor.solidity.Block
import com.dell.research.bc.eth.solidity.editor.solidity.ContractOrLibrary
import com.dell.research.bc.eth.solidity.editor.solidity.FunctionDefinition
import com.dell.research.bc.eth.solidity.editor.solidity.IfStatement
import com.dell.research.bc.eth.solidity.editor.solidity.InheritanceSpecifier
import com.dell.research.bc.eth.solidity.editor.solidity.ReturnStatement
import com.dell.research.bc.eth.solidity.editor.solidity.Solidity
import com.dell.research.bc.eth.solidity.editor.solidity.StandardVariableDeclaration
import com.dell.research.bc.eth.solidity.editor.solidity.VisibilityEnum
import com.dell.research.bc.eth.solidity.editor.solidity.VisibilitySpecifier
import com.google.common.collect.Sets
import java.util.Collection
import java.util.Set
import org.eclipse.emf.ecore.EObject

import static extension org.eclipse.xtext.EcoreUtil2.*
import java.util.HashSet
import com.dell.research.bc.eth.solidity.editor.solidity.VariableDeclarationExpression
import com.dell.research.bc.eth.solidity.editor.solidity.Variable

// See page 202 of Xtext book
class SolidityUtil {

	public static Set<String> MESSAGE_MEMBERS = Sets.newHashSet("sender", "value", "data", "gas", "sig")
	public static Set<String> TRANSACTION_MEMBERS = Sets.newHashSet("gasprice", "origin")
	public static Set<String> CURRENTBLOCK_MEMBERS = Sets.newHashSet("coinbase", "difficulty", "gaslimit", "number",
		"blockhash", "timestamp")
	public static Set<String> ADDRESS_MEMBERS = Sets.newHashSet("balance", "send")

	def static containingSolidity(EObject e) {
		e.getContainerOfType(typeof(Solidity))
	}

	def static returnStatement(FunctionDefinition fd) {
		fd.block.statements.typeSelect(typeof(ReturnStatement)).head
	}

	def static containingContractOrLibrary(EObject e) {
		e.getContainerOfType(ContractOrLibrary)
	}

	def static containingFunction(EObject e) {
		e.getContainerOfType(FunctionDefinition)
	}

	def static containingIfStatement(EObject e) {
		e.getContainerOfType(IfStatement)
	}

	def static containingBlock(EObject e) {
		e.getContainerOfType(Block)
	}

	def static classHierarchy(ContractOrLibrary cl) {
		val toVisit = <InheritanceSpecifier>newHashSet();
		toVisit.addAll(cl.inheritanceSpecifiers)
		val visited = <ContractOrLibrary>newHashSet();
		// visited.add(cl)
		while (!toVisit.empty) {
			var is = toVisit.last
			toVisit.remove(is)
			var current = is.superType
			// Seen this one before?
			if (!visited.contains(current)) {
				// No
				toVisit.addAll(current.inheritanceSpecifiers)
				visited.add(current)
			}
		} // while !toVisit.empty
		visited
	}

	def static isPrivate(VisibilitySpecifier vd) {
		if(vd == null) return false;
		VisibilityEnum.PRIVATE.literal.equals(vd.visibility.literal)
	}

	def static isPrivate(StandardVariableDeclaration vd) {
		vd.optionalElements.filter(VisibilitySpecifier).exists[it.isPrivate]
	}

	def static isPrivate(FunctionDefinition fd) {
		fd.optionalElements.filter(VisibilitySpecifier).exists[it.isPrivate]
	}

	def static toVisiblilityKind(FunctionDefinition fd) {
		return toVisiblilityKind(fd.optionalElements.filter(VisibilitySpecifier).toList)
	}

	def static toVisiblilityKind(StandardVariableDeclaration vd) {
		return toVisiblilityKind(vd.optionalElements.filter(VisibilitySpecifier).toList)
	}

	/**
	 * Returns the visibility kind. Public for default. 
	 */
	def static toVisiblilityKind(Collection<VisibilitySpecifier> vs) {
		if (vs.isEmpty) // public is the default
			return VisibilityEnum::PUBLIC

		return vs.get(0).visibility
	}

	/**
	 * Returns all defined in and out parameters.
	 */
	def static Collection<Variable> getAllParameters(EObject model) {
		val parameters = new HashSet

		var fd = model.getContainerOfType(FunctionDefinition)
		if (fd != null) {
			fd.parameters?.parameters?.filter(VariableDeclarationExpression).forEach [
				parameters.add(it.variable)
			]
			fd.parameters?.parameters?.filter(StandardVariableDeclaration).forEach [
				parameters.add(it.variable)
			]

			fd.returnParameters?.parameters?.forEach [
				parameters.add(it.variable)
			]
		}
		return parameters
	}

	/**
	 * Get all accessible contacts.  
	 */
	def static getAllAccesibleContractsOrLibraries(EObject model) {
		var s = model.getContainerOfType(Solidity)
		val uri = model.eResource.URI;
		val urit = uri.trimSegments(1)
		s.importDirective.forEach[
			//TODO: better check for the path
			var filename = it.importURI.substring(2)
			var uri1 = urit
			var uri2 = uri1.appendSegment(filename)
			try {
				model.resourceSet.getResource(uri2,true)
			} catch (Exception exception) {
			}
		]
		var list = model.resourceSet.allContents.filter(ContractOrLibrary).toList
		return list
	// TODO: this need to be filtered by the import statements
	}

	/**
	 * Returns all field defined by the type or the super types.
	 */
	def static getAllFields(EObject model) {
		var cl = model.getContainerOfType(ContractOrLibrary)
		var ch = classHierarchy(cl)
		
		val allAllField = new HashSet
		var b = cl.body
		if(b!=null)
			allAllField.addAll(b.variables.filter(StandardVariableDeclaration))
		ch.forEach [
			if (it.body != null)
				allAllField.addAll(it.body?.variables.filter(StandardVariableDeclaration).filter[!isPrivate(it)])
		]

		return allAllField;
	}

	/**
	 * Returns all structs defined by the type or the super types.
	 */
	def static getAllStructs(EObject model) {
		var cl = model.getContainerOfType(ContractOrLibrary)
		var ch = classHierarchy(cl)

		val allStructs = new HashSet
		var b = cl.body
		if(b!=null)
			allStructs.addAll(b.structs)

		ch.forEach [
			if (it.body != null)
				allStructs.addAll(it.body.structs)
		]
		return allStructs
	}

	/**
	 * Returns all enums defined by the type or the super types.
	 */
	def static getAllEnums(EObject model) {
		var cl = model.getContainerOfType(ContractOrLibrary)
		var ch = classHierarchy(cl)

		val allEnums = new HashSet
		var b = cl.body
		if(b!=null)
			allEnums.addAll(b.enums)
		ch.forEach [
			if (it.body != null)
				allEnums.addAll(it.body.enums)
		]
		return allEnums;
	}

	/**
	 * Returns all events defined by the type or the super types.
	 */
	def static getAllEvents(EObject model) {
		var cl = model.getContainerOfType(ContractOrLibrary)
		var ch = classHierarchy(cl)

		val allEvents = new HashSet
		var b = cl.body
		if(b!=null)
			allEvents.addAll(b.events)
		ch.forEach [
			if (it.body != null)
				allEvents.addAll(it.body.events)
		]
		return allEvents;
	}

} // SolidityUtil
