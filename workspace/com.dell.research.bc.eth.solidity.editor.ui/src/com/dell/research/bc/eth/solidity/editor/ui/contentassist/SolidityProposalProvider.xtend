/*******************************************************************************
 * Copyright (c) 2015 Dell Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors:
 *     Daniel Ford, Dell Corporation - initial API and implementation
 *     Urs Zeidler
 *******************************************************************************/
package com.dell.research.bc.eth.solidity.editor.ui.contentassist

import com.dell.research.bc.eth.solidity.editor.SolidityUtil
import com.dell.research.bc.eth.solidity.editor.solidity.Block
import com.dell.research.bc.eth.solidity.editor.solidity.Contract
import com.dell.research.bc.eth.solidity.editor.solidity.ContractOrLibrary
import com.dell.research.bc.eth.solidity.editor.solidity.ElementaryType
import com.dell.research.bc.eth.solidity.editor.solidity.Expression
import com.dell.research.bc.eth.solidity.editor.solidity.ExpressionStatement
import com.dell.research.bc.eth.solidity.editor.solidity.FunctionDefinition
import com.dell.research.bc.eth.solidity.editor.solidity.Library
import com.dell.research.bc.eth.solidity.editor.solidity.Mapping
import com.dell.research.bc.eth.solidity.editor.solidity.QualifiedIdentifier
import com.dell.research.bc.eth.solidity.editor.solidity.SpecialExpression
import com.dell.research.bc.eth.solidity.editor.solidity.SpecialVariables
import com.dell.research.bc.eth.solidity.editor.solidity.StandardVariableDeclaration
import com.dell.research.bc.eth.solidity.editor.solidity.Statement
import com.dell.research.bc.eth.solidity.editor.solidity.StructDefinition
import com.dell.research.bc.eth.solidity.editor.solidity.VarVariableDeclaration
import com.dell.research.bc.eth.solidity.editor.solidity.VariableDeclarationExpression
import java.util.HashSet
import java.util.Iterator
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor

import static com.dell.research.bc.eth.solidity.editor.SolidityUtil.*

import static extension org.eclipse.xtext.EcoreUtil2.*
import com.dell.research.bc.eth.solidity.editor.solidity.ForStatement
import java.util.ArrayList

/**
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
class SolidityProposalProvider extends AbstractSolidityProposalProvider {

	static final String IMG_LOCAL_VAR = 'localvariable_obj.png';
	
	override complete_PrimaryExpression(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		println("complete_PrimaryExpression:" + model + "::" + context.prefix)

		fillAllPossibleProposals(model, acceptor, context, context.prefix, false)
	}

//	override complete_ComparisonOpEnum(EObject model, RuleCall ruleCall, ContentAssistContext context,
//		ICompletionProposalAcceptor acceptor) {
//		println("complete_ComparisonOpEnum:" + model + "::" + context.prefix)
//		if (hasQualifier(context.prefix) || hasIndex(context.prefix) || hasArgument(context.prefix))
//			return;
//
//		fillAllPossibleProposals(model, acceptor, context, context.prefix, false)
//	}

	override complete_Assignment(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {

		if (!( model instanceof com.dell.research.bc.eth.solidity.editor.solidity.Assignment))
			return;

		println("complete_Assignment:" + model + "::" + context.prefix)
		fillAllPossibleProposals(model, acceptor, context, context.prefix, false)
	}

	override complete_Comparison(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {

		if (!( model instanceof Expression))
			return;

		println("complete_Comparison:" + model + "::" + context.prefix)
		fillAllPossibleProposals(model, acceptor, context, context.prefix, false)
	}

//	override complete_Expression(EObject model, RuleCall ruleCall, ContentAssistContext context,
//		ICompletionProposalAcceptor acceptor) {
//		println("complete_Expression:" + model + "::" + context.prefix)
//	}
//
//	override complete_ExpressionStatement(EObject model, RuleCall ruleCall, ContentAssistContext context,
//		ICompletionProposalAcceptor acceptor) {
//		println("complete_ExpressionStatement:" + model + "::" + context.prefix)
//	}
	override complete_Arguments(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {

		if (!hasArgument(context.prefix))
			return;

		println("complete_Arguments:" + model + "::" + context.prefix)
		val b = model.getContainerOfType(Block)
		fillAllFieldsAndMethods(model, acceptor, context, context.prefix)
		fillAllLocalVariables(b.statements, acceptor, context, context.prefix)
		fillAllParameters(model, acceptor, context, context.prefix)
	}

	override complete_StandardTypeWithoutQualifiedIdentifier(EObject model, RuleCall ruleCall,
		ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		println("complete_StandardTypeWithoutQualifiedIdentifier:" + model + "::" + context.prefix)

		fillAllPossibleProposals(model, acceptor, context, context.prefix, true)
	}

	override complete_Index(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {

		if (!hasIndex(context.prefix))
			return;
		println("complete_Index:" + model + "::" + context.prefix)
		fillAllFieldsAndMethods(model, acceptor, context, context.prefix)
		var b = model.getContainerOfType(Block)
		if (b != null) {
			fillAllLocalVariables(b.statements, acceptor, context, context.prefix)
			fillAllParameters(model, acceptor, context, context.prefix)
		}
	}

	override completeQualifiedIdentifier_Qualifiers(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {

		if (!hasQualifier(context.prefix))
			return;
		println("completeQualifiedIdentifier_Qualifiers:" + model + "::" + context.prefix)
		if (model instanceof QualifiedIdentifier) {
			var type1 = model as QualifiedIdentifier
			var index = type1.qualifiers.indexOf(context.previousModel)
			if (index > 0) { // the case qi.q1.q2...qn
			// TODO: resolve the complete type 
				return
			}

			val fieldname = type1.identifier
			var t = resolveType(fieldname, model)
			if(t == null) t = resolveTypename(fieldname, model)

			if (t instanceof Mapping) {
				var m = t as Mapping
				var mt = m.valueType
				completeQualifiedIdentifier_Qualifiers(mt, assignment, context, acceptor)
			} else if (t != null) {
				fillForResolvedType(t, acceptor, context, context.prefix)
			}
		}
	}

	override completeDefinitionBody_Variables(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		println("completeDefinitionBody_Variables:" + model + "::" + context.prefix)

		val c = getAllAccesibleContractsOrLibraries(model) // model.resourceSet.allContents.filter(ContractOrLibrary)
		fillTypes(c, acceptor, context)
		fillAllInnerTypes(model, acceptor, context, false)
	}

	override completeSpecialExpression_FieldOrMethod(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		println("completeSpecialExpression_FieldOrMethod:" + model + "::" + context.prefix)

		switch ((model as SpecialExpression).type) {
			case SUPER: completeSuperExpression_FieldOrMethod(model, assignment, context, acceptor)
			case THIS: completeThisExpression_FieldOrMethod(model, assignment, context, acceptor)
		}
	}

	override completeSpecialVariables_Field(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		println("completeSpecialVariables_Field:" + model + "::" + context.prefix)

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

	/**
	 * Check if the last qualifier is an Index.
	 */
	private def hasIndex(String prefix) {
		return prefix.equals("[")
	}

	/**
	 * Check if the last qualifier is an Arguments.
	 */
	private def hasArgument(String prefix) {
		return prefix.equals("(")
	}

	/**
	 * Check if the last qualifier is a dot.
	 */
	private def hasQualifier(String prefix) {
		return prefix.equals(".")
	}

	/**
	 * Fills the proposal for the resolved type( the grammar type).
	 */
	private def fillForResolvedType(EObject t, ICompletionProposalAcceptor acceptor, ContentAssistContext context,
		String matchingPrefix) {
		if (t instanceof Contract) {
			fillAllFieldsAndMethods(t, acceptor, context, matchingPrefix)
		} else if (t instanceof Library) {
			fillAllFieldsAndMethods(t, acceptor, context, matchingPrefix)
		} else if (t instanceof StructDefinition) {
			fillAllLocalVariables((t as StructDefinition).members, acceptor, context, matchingPrefix)
		} else if (t instanceof ElementaryType) {
			var e = (t as ElementaryType)
			switch (e.name) {
				case ADDRESS: {
					SolidityUtil.ADDRESS_MEMBERS.forEach [
						acceptor.accept(createCompletionProposal(matchingPrefix + it, it, null, context))
					]
				}
				default: {
				}
			}
		}
	}

	/**
	 * Get all accessible contacts.  
	 */
	private def getAllAccesibleContractsOrLibraries(EObject model) {
		model.resourceSet.allContents.filter(ContractOrLibrary)
	// TODO: this need to be filtered by the import statements
	}

	/**
	 * Returns the type of an given identifier or typename.
	 */
	private def resolveType(String identifier, EObject model) {
		val fields = getAllFields(model)
		val foundfield = fields.findFirst [
			it.variable?.name.equals(identifier)
		]

		var t = foundfield?.type

		if (t == null) { // check for a local variable
			var b = model.getContainerOfType(Block)
			if (b != null) {
				var tt = b.statements.filter(ExpressionStatement).filter [
					(it.expression instanceof VariableDeclarationExpression) &&
						((it.expression as VariableDeclarationExpression).type instanceof QualifiedIdentifier)
				].findFirst [
					(it.expression as VariableDeclarationExpression).variable.name.equals(identifier)
				]
				if (tt != null)
					t = (tt?.expression as VariableDeclarationExpression).type
			}
		}

		if (t instanceof QualifiedIdentifier) {
			var qi = t as QualifiedIdentifier
			val typename = qi.identifier

			return resolveTypename(typename, model)
		} else if (t instanceof Mapping) {
			return t
		} else if (t instanceof ElementaryType) {
			return t
		}
	}

	private def resolveTypename(String typename, EObject model) {
		var type = getAllAccesibleContractsOrLibraries(model).findFirst [
			it.name.equals(typename)
		]
		if (type != null)
			return type

		var stype = getAllStructs(model).findFirst [
			it.name.equals(typename)
		]
		if (stype != null)
			return stype

		var etype = getAllEnums(model).findFirst [
			it.name.equals(typename)
		]
		if (etype != null)
			return etype
	}

	/**
	 * Fill all variables defined in the given block. 
	 */
	def private fillAllLocalVariables(List<? super Statement> statements, ICompletionProposalAcceptor acceptor,
		ContentAssistContext context, String matchingPrefix) {
		val variableDeclaration = new HashSet<VariableDeclarationExpression>()
		statements.filter(ExpressionStatement).filter [
			it.expression instanceof VariableDeclarationExpression
		].forEach [
			variableDeclaration.add(it.expression as VariableDeclarationExpression)
		]
		val standardVariableDeclaration = new HashSet<StandardVariableDeclaration>()
		statements.filter(StandardVariableDeclaration).forEach [
			standardVariableDeclaration.add(it)
		]
		statements.filter(ForStatement).forEach[
			 if (it.initExpression instanceof StandardVariableDeclaration) {
			 	standardVariableDeclaration.add(it.initExpression as StandardVariableDeclaration)
			 } 			
		]
		val varVariableDeclaration = new HashSet<VarVariableDeclaration>()
		statements.filter(ExpressionStatement).filter [
			it.expression instanceof VarVariableDeclaration
		].forEach [
			varVariableDeclaration.add(it.expression as VarVariableDeclaration)
		]
		variableDeclaration.forEach [
			acceptor.accept(
				createCompletionProposal(matchingPrefix + it.variable.name, labelProvider.getText(it), labelProvider.getImage(IMG_LOCAL_VAR), context))
		]
		varVariableDeclaration.forEach [
			acceptor.accept(
				createCompletionProposal(matchingPrefix + it.variable.name, labelProvider.getText(it), labelProvider.getImage(IMG_LOCAL_VAR), context))
		]
		standardVariableDeclaration.forEach [
			acceptor.accept(
				createCompletionProposal(matchingPrefix + it.variable.name, labelProvider.getText(it), labelProvider.getImage(IMG_LOCAL_VAR), context))
		]
	}

//	/**
//	 * Simple helper.
//	 */
//	private def toNameAndType(EObject vd) {
//		switch (vd) {
//			VariableDeclarationExpression: {
//				return vd.variable.name + " : " + labelProvider.getText(vd.type)
//			}
//			VarVariableDeclaration: {
//				return vd.variable.name + " : " + labelProvider.getText(vd.varType)
//			}
//			StandardVariableDeclaration: {
//				return vd.variable.name + " : " + labelProvider.getText(vd.type)
//			}
//		}
//	}

	/**
	 * Fills all proposal types.
	 */
	private def fillAllPossibleProposals(EObject model, ICompletionProposalAcceptor acceptor,
		ContentAssistContext context, String matchingPrefix, boolean includeTypes) {
		var Block block = null
		var Statement statement = null

		if (model instanceof Block) {
			var test = context.currentNode.parent.semanticElement
			statement = test.getContainerOfType(Statement)
			block = model as Block
		} else if (model instanceof Statement) {
			block = model.getContainerOfType(Block)
			statement = model as Statement
		} else if (model instanceof Expression) {
			block = model.getContainerOfType(Block)
			statement = model.getContainerOfType(Statement)
		}

		if(block == null) return;
		do {
			var index = block.statements.indexOf(statement)
			var List<? super Statement> statements = new ArrayList(block.statements)
			if (index != -1) {
				statements = block.statements.subList(0, index)
			}
			// TODO: add the declared variable of the for statement
			if (block.eContainer instanceof ForStatement) {
				statements.add((block.eContainer as ForStatement))
			}
			fillAllLocalVariables(statements, acceptor, context, context.prefix)

			var b1 = block.eContainer.getContainerOfType(Block)
			if (b1 != null) { // move the blocks upward to collect the other lv
				block = b1
				statement = null
			} else {
				block = null;
			}
		} while (block != null)

		val c = getAllAccesibleContractsOrLibraries(model)
		fillAllParameters(model, acceptor, context, context.prefix)
		fillAllFieldsAndMethods(model, acceptor, context, context.prefix)
		if (includeTypes) {
			fillTypes(c, acceptor, context)
			fillAllInnerTypes(model, acceptor, context, true)
		}
	}

	/**
	 * Fills the types.
	 */
	def private fillTypes(Iterator<ContractOrLibrary> libraries, ICompletionProposalAcceptor acceptor,
		ContentAssistContext context) {
		libraries.forEach [
			acceptor.accept(
				createCompletionProposal(it.name, labelProvider.getText(it), labelProvider.getImage(it), context));
		]
	}

	/**
	 * Returns all field defined by the type or the super types.
	 */
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

	/**
	 * Returns all structs defined by the type or the super types.
	 */
	private def getAllStructs(EObject model) {
		var cl = model.getContainerOfType(ContractOrLibrary)
		var ch = classHierarchy(cl)

		val allStructs = new HashSet
		allStructs.addAll(cl.body.structs)

		ch.forEach [
			allStructs.addAll(it.body.structs)
		]
		allStructs
	}

	/**
	 * Returns all enums defined by the type or the super types.
	 */
	private def getAllEnums(EObject model) {
		var cl = model.getContainerOfType(ContractOrLibrary)
		var ch = classHierarchy(cl)

		val allEnums = new HashSet
		allEnums.addAll(cl.body.enums)
		ch.forEach [
			allEnums.addAll(it.body.enums)
		]
		allEnums
	}

	/**
	 * Returns all events defined by the type or the super types.
	 */
	private def getAllEvents(EObject model) {
		var cl = model.getContainerOfType(ContractOrLibrary)
		var ch = classHierarchy(cl)

		val allEvents = new HashSet
		allEvents.addAll(cl.body.events)
		ch.forEach [
			allEvents.addAll(it.body.events)
		]
		allEvents
	}

	/**
	 * Fills all the defined parameters.
	 */
	private def fillAllParameters(EObject model, ICompletionProposalAcceptor acceptor, ContentAssistContext context,
		String matchingPrefix) {
		val fd = model.getContainerOfType(FunctionDefinition)
		fd?.parameters.parameters
		fillAllLocalVariables(fd.parameters?.parameters, acceptor, context, matchingPrefix)
	}

	/**
	 * Add the inner types as proposal.
	 */
	private def fillAllInnerTypes(EObject model, ICompletionProposalAcceptor acceptor, ContentAssistContext context,
		boolean includeEvents) {
		val allStructs = getAllStructs(model)
		val allEnums = getAllEnums(model)
		val allEvents = getAllEvents(model)

		allStructs.forEach [
			acceptor.accept(
				createCompletionProposal(it.name, labelProvider.getText(it), labelProvider.getImage(it), context));
		]
		allEnums.forEach [
			acceptor.accept(
				createCompletionProposal(it.name, labelProvider.getText(it), labelProvider.getImage(it), context));
		]
		if (includeEvents) {
			allEvents.forEach [
				acceptor.accept(
					createCompletionProposal(it.name, labelProvider.getText(it), labelProvider.getImage(it), context));
			]
		}
	}

	/**
	 * Fills all the not private members of the ContractOrLibrary containing the model.
	 */
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
			acceptor.accept(createCompletionProposal(matchingPrefix + it.variable.name,  labelProvider.getText(it), // labelProvider.getText(it.variable),
			labelProvider.getImage(it), context));
		]
		allMethods.forEach [
			acceptor.accept(
				createCompletionProposal(matchingPrefix + it.name + "()", labelProvider.getText(it),
					labelProvider.getImage(it), context));
		]
	}

	/**
	 * Added all fields and methods for the this expression.
	 */
	private def completeThisExpression_FieldOrMethod(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		fillAllFieldsAndMethods(model, acceptor, context, ".")
	}

	/**
	 * Added the fields and methods for the super expression.
	 */
	private def completeSuperExpression_FieldOrMethod(EObject model, Assignment assignment,
		ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
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
	}
	