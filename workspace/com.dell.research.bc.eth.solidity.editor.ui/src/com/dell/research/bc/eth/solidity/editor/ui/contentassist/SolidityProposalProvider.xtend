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
package com.dell.research.bc.eth.solidity.editor.ui.contentassist

import com.dell.research.bc.eth.solidity.editor.SolidityUtil
import com.dell.research.bc.eth.solidity.editor.solidity.ContractOrLibrary
import com.dell.research.bc.eth.solidity.editor.solidity.SpecialVariables
import com.dell.research.bc.eth.solidity.editor.solidity.QualifiedIdentifier
import com.dell.research.bc.eth.solidity.editor.solidity.StandardVariableDeclaration
import java.util.HashSet
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor

import static com.dell.research.bc.eth.solidity.editor.SolidityUtil.*

import static extension org.eclipse.xtext.EcoreUtil2.*
import com.dell.research.bc.eth.solidity.editor.solidity.SpecialExpression

/**
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
class SolidityProposalProvider extends AbstractSolidityProposalProvider {

	override complete_StandardTypeWithoutQualifiedIdentifier(EObject model, RuleCall ruleCall,
		ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		fillAllFieldsAndMethods(model, acceptor, context, "")
	}

	override completeQualifiedIdentifier_Qualifiers(EObject model, Assignment assignment, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		var type1 = model as QualifiedIdentifier
		val fieldname = type1.identifier
		
		val allAllField = getAllFields(model)
		val foundfield =  allAllField.findFirst[
			it.variable.name.equals(fieldname)
		]
		if(foundfield==null) return
		var qi = foundfield.type as QualifiedIdentifier
		val typename = qi.identifier;
		var type = model.resourceSet.allContents.filter(ContractOrLibrary).findFirst[
			it.name.equals(typename)			
		]
		
		fillAllFieldsAndMethods(type, acceptor, context, ".")		
	}

	private def completeThisExpression_FieldOrMethod(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		fillAllFieldsAndMethods(model, acceptor, context, ".")
	}

	private def getAllFields(EObject model) {
		var cl = model.getContainerOfType(ContractOrLibrary)
		var ch = classHierarchy(cl)

		val allAllField = new HashSet
		allAllField.addAll(cl.body.variables.filter(StandardVariableDeclaration))
		ch.forEach [
			allAllField.addAll(it.body.variables.filter(StandardVariableDeclaration).filter[!isPrivate(it)])
		]
		
		allAllField
	}


	private def fillAllFieldsAndMethods(EObject model, ICompletionProposalAcceptor acceptor,
		ContentAssistContext context, String matchingPrefix) {
		var cl = model.getContainerOfType(ContractOrLibrary)
		var ch = classHierarchy(cl)

		val allAllField = new HashSet
		val allMethods = new HashSet

		allAllField.addAll(cl.body.variables.filter(StandardVariableDeclaration))
		allMethods.addAll(cl.body.functions)
		ch.forEach [
			allAllField.addAll(it.body.variables.filter(StandardVariableDeclaration).filter[!isPrivate(it)])
			allMethods.addAll(it.body.functions.filter[!isPrivate(it)])
		]

		allAllField.forEach [
			acceptor.accept(
				createCompletionProposal(matchingPrefix + it.variable.name, labelProvider.getText(it.variable),
					labelProvider.getImage(it), context));
		]
		allMethods.forEach [
			acceptor.accept(
				createCompletionProposal(matchingPrefix + it.name + "()", labelProvider.getText(it),
					labelProvider.getImage(it), context));
		]
	}

	private def completeSuperExpression_FieldOrMethod(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		var cl = model.getContainerOfType(ContractOrLibrary)
		var ch = classHierarchy(cl)

		val allAllField = new HashSet
		val allMethods = new HashSet

		ch.forEach [
			allAllField.addAll(it.body.variables.filter(StandardVariableDeclaration))
			allMethods.addAll(it.body.functions)
		]

		allAllField.forEach [
			acceptor.accept(
				createCompletionProposal("." + it.variable.name, labelProvider.getText(it.variable),
					labelProvider.getImage(it), context));
		]
		allMethods.forEach [
			acceptor.accept(
				createCompletionProposal("." + it.name, labelProvider.getText(it), labelProvider.getImage(it),
					context));
			]
		}

	override completeSpecialExpression_FieldOrMethod(EObject model, Assignment assignment, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		switch ((model as SpecialExpression).type) {
				case SUPER: completeSuperExpression_FieldOrMethod(model,assignment,context,acceptor)
				case THIS: completeThisExpression_FieldOrMethod(model,assignment,context,acceptor)
			}
	}


	override completeSpecialVariables_Field(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		switch ((model as SpecialVariables).type) {
			case MSG:
				SolidityUtil.MESSAGE_MEMBERS.forEach [
					acceptor.accept(createCompletionProposal(it, it, null, context));
				]
			case BLOCK:
				SolidityUtil.CURRENTBLOCK_MEMBERS.forEach [
					acceptor.accept(createCompletionProposal(it, it, null, context));
				]
			case TX:
				SolidityUtil.TRANSACTION_MEMBERS.forEach [
					acceptor.accept(createCompletionProposal(it, it, null, context));
				]
		}
	}
		
}