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
import com.dell.research.bc.eth.solidity.editor.solidity.EnumDefinition
import com.dell.research.bc.eth.solidity.editor.solidity.Expression
import com.dell.research.bc.eth.solidity.editor.solidity.ExpressionStatement
import com.dell.research.bc.eth.solidity.editor.solidity.ForStatement
import com.dell.research.bc.eth.solidity.editor.solidity.FunctionCallListArguments
import com.dell.research.bc.eth.solidity.editor.solidity.FunctionDefinition
import com.dell.research.bc.eth.solidity.editor.solidity.Index
import com.dell.research.bc.eth.solidity.editor.solidity.Library
import com.dell.research.bc.eth.solidity.editor.solidity.Mapping
import com.dell.research.bc.eth.solidity.editor.solidity.QualifiedIdentifier
import com.dell.research.bc.eth.solidity.editor.solidity.Solidity
import com.dell.research.bc.eth.solidity.editor.solidity.SpecialExpression
import com.dell.research.bc.eth.solidity.editor.solidity.SpecialVariables
import com.dell.research.bc.eth.solidity.editor.solidity.StandardVariableDeclaration
import com.dell.research.bc.eth.solidity.editor.solidity.Statement
import com.dell.research.bc.eth.solidity.editor.solidity.StructDefinition
import com.dell.research.bc.eth.solidity.editor.solidity.VarVariableDeclaration
import com.dell.research.bc.eth.solidity.editor.solidity.Variable
import com.dell.research.bc.eth.solidity.editor.solidity.VariableDeclarationExpression
import java.util.ArrayList
import java.util.Collection
import java.util.HashSet
import java.util.List
import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor

import static com.dell.research.bc.eth.solidity.editor.SolidityUtil.*

import static extension org.eclipse.xtext.EcoreUtil2.*

/**
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
class SolidityProposalProvider extends AbstractSolidityProposalProvider {

	static final String IMG_LOCAL_VAR = 'localvariable_obj.png';
	static final String IMG_PUBLIC_FIELD = 'field_public_obj.png'
	static final String IMG_PUBLIC_METHOD = 'methpub_obj.png'

	override complete_PrimaryExpression(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		if (model instanceof FunctionCallListArguments) {
			complete_Arguments(model, ruleCall, context, acceptor)
			return;
		} else if (model instanceof Index) {
			complete_Index(model, ruleCall, context, acceptor)
			return;
		}

		fillAllPossibleProposals(model, acceptor, context, context.prefix, false)
	}

	override complete_Assignment(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {

		if (!( model instanceof com.dell.research.bc.eth.solidity.editor.solidity.Assignment))
			return;

		fillAllPossibleProposals(model, acceptor, context, context.prefix, false)
	}

	override complete_Comparison(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {

		if (!( model instanceof Expression))
			return;

		fillAllPossibleProposals(model, acceptor, context, context.prefix, false)
	}

	override complete_Arguments(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {

		if (!(model instanceof FunctionCallListArguments))
			return;

		val b = model.getContainerOfType(Block)
		val allLocals = getAllValidLocalStatements(b, model.getContainerOfType(Statement))

		fillAllLocalVariables(allLocals, acceptor, context, context.prefix, IMG_LOCAL_VAR)
		fillAllParameters(model, acceptor, context, context.prefix)
		fillAllFieldsAndMethods(model, acceptor, context, context.prefix)
	}

	override complete_StandardTypeWithoutQualifiedIdentifier(EObject model, RuleCall ruleCall,
		ContentAssistContext context, ICompletionProposalAcceptor acceptor) {

		fillAllPossibleProposals(model, acceptor, context, context.prefix, true)
	}

	override complete_Index(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {

		if (!(model instanceof Index))
			return;

		fillAllFieldsAndMethods(model, acceptor, context, context.prefix)
		var b = model.getContainerOfType(Block)
		if (b != null) {
			fillAllLocalVariables(b.statements, acceptor, context, context.prefix, IMG_LOCAL_VAR)
			fillAllParameters(model, acceptor, context, context.prefix)
		}
	}

	override completeQualifiedIdentifier_Qualifiers(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {

		if (!hasQualifier(context.prefix))
			return;
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
		val c = getAllAccesibleContractsOrLibraries(model)
		fillTypes(c, acceptor, context)
		fillAllInnerTypes(model, acceptor, context, false, context.prefix)
	}

	override completeSpecialExpression_FieldOrMethod(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		switch ((model as SpecialExpression).type) {
			case SUPER: completeSuperExpression_FieldOrMethod(model, assignment, context, acceptor)
			case THIS: completeThisExpression_FieldOrMethod(model, assignment, context, acceptor)
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

	/**
	 * Check if the last qualifier is a dot.
	 */
	private def hasQualifier(String prefix) {
		return prefix.equals(".")
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
			var statement = model.getContainerOfType(Statement)
			var allLocals = getAllValidLocalStatements(b, statement)

			if (!allLocals.isEmpty) {
				var tt = allLocals.filter(ExpressionStatement).filter [
					(it.expression instanceof VariableDeclarationExpression) &&
						((it.expression as VariableDeclarationExpression).type instanceof QualifiedIdentifier)
				].findFirst [
					(it.expression as VariableDeclarationExpression).variable?.name.equals(identifier)
				]
				if (tt != null)
					t = (tt?.expression as VariableDeclarationExpression).type

			}
		}
		if (t == null) { // check for a parameter
			var epara = getAllParameters(model).filter(Variable).findFirst [
				it.name.equals(identifier)
			]
			if (epara != null) {
				if (epara.eContainer instanceof StandardVariableDeclaration) {
					t = (epara.eContainer as StandardVariableDeclaration).type
				}
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
	def private fillAllLocalVariables(Collection<? super Statement> statements, ICompletionProposalAcceptor acceptor,
		ContentAssistContext context, String matchingPrefix, String imageUrl) {
		var mp = matchingPrefix
		if (!hasQualifier(mp))
			mp = ""

		val mpv = mp

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
		statements.filter(ForStatement).forEach [
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
			if ((it.variable != null && it.variable.name.startsWith(mpv)) || hasQualifier(matchingPrefix))
				acceptor.accept(
					createCompletionProposal(mpv + it.variable.name, labelProvider.getText(it),
						labelProvider.getImage(imageUrl), context))
		]
		varVariableDeclaration.forEach [
			if ((it.variable != null && it.variable.name.startsWith(mpv)) || hasQualifier(matchingPrefix))
				acceptor.accept(
					createCompletionProposal(mpv + it.variable.name, labelProvider.getText(it),
						labelProvider.getImage(imageUrl), context))
		]
		standardVariableDeclaration.forEach [
			if ((it.variable != null && it.variable.name.startsWith(mpv)) || hasQualifier(matchingPrefix))
				acceptor.accept(
					createCompletionProposal(mpv + it.variable.name, labelProvider.getText(it),
						labelProvider.getImage(imageUrl), context))
		]
	}

	/**
	 * Fills all proposal types.
	 */
	private def fillAllPossibleProposals(EObject model, ICompletionProposalAcceptor acceptor,
		ContentAssistContext context, String matchingPrefix, boolean includeTypes) {
		if(model == null) return;
		var Block block = null
		var Statement statement = null

		if (model instanceof Block) {
			var test = context.currentNode.parent.semanticElement
			statement = test.getContainerOfType(Statement)
			block = model as Block
		} else if (model instanceof Statement) {
			block = model.getContainerOfType(Block)
			statement = findMatchingStatement(block, model)
		} else if (model instanceof Expression) {
			block = model.getContainerOfType(Block)
			statement = model.getContainerOfType(Statement)
		}

		var allLocalVariables = getAllValidLocalStatements(block, statement)
		fillAllLocalVariables(allLocalVariables, acceptor, context, context.prefix, IMG_LOCAL_VAR)

		val c = getAllAccesibleContractsOrLibraries(model)
		fillAllParameters(model, acceptor, context, context.prefix)
		fillAllFieldsAndMethods(model, acceptor, context, context.prefix)
		if (includeTypes) {
			fillTypes(c, acceptor, context)
			fillAllInnerTypes(model, acceptor, context, true, matchingPrefix)
		}
	}

	/**
	 * Search the next statement (parent) defined in the block. 
	 */
	private def Statement findMatchingStatement(Block block, EObject model) {
		if (block.statements.indexOf(model) != -1)
			return model as Statement
		if(model.eContainer == null || model.eContainer instanceof Solidity) return null;

		return findMatchingStatement(block, model.eContainer)
	}

	/**
	 * Fills the proposal for the resolved type( the grammar type).
	 */
	private def fillForResolvedType(EObject t, ICompletionProposalAcceptor acceptor, ContentAssistContext context,
		String matchingPrefix) {
		var mp = matchingPrefix
		if (!hasQualifier(mp))
			mp = ""

		val mpv = mp

		if (t instanceof Contract) {
			fillAllFieldsAndMethods(t, acceptor, context, matchingPrefix)
		} else if (t instanceof Library) {
			fillAllFieldsAndMethods(t, acceptor, context, matchingPrefix)
		} else if (t instanceof StructDefinition) {
			fillAllLocalVariables((t as StructDefinition).members, acceptor, context, matchingPrefix, IMG_PUBLIC_FIELD)
		} else if (t instanceof EnumDefinition) {
			(t as EnumDefinition).members.forEach [
				if ((it.name != null && it.name.startsWith(mpv)) || hasQualifier(matchingPrefix))
					acceptor.accept(
						createCompletionProposal(mpv + it.name, labelProvider.getText(it), labelProvider.getImage(it),
							context))
			]
		} else if (t instanceof ElementaryType) {
			var e = (t as ElementaryType)
			switch (e.name) {
				case ADDRESS: {
					SolidityUtil.ADDRESS_MEMBERS.forEach [
						acceptor.accept(
							createCompletionProposal(matchingPrefix + it, it, labelProvider.getImage(IMG_PUBLIC_METHOD),
								context))
					]
				}
				default: {
				}
			}
		}
	}

	/**
	 * Fills the types.
	 */
	def private fillTypes(Collection<ContractOrLibrary> libraries, ICompletionProposalAcceptor acceptor,
		ContentAssistContext context) {
		libraries.forEach [
			acceptor.accept(
				createCompletionProposal(it.name, labelProvider.getText(it), labelProvider.getImage(it), context));
		]
	}

	/**
	 * Fills all the defined parameters.
	 */
	private def fillAllParameters(EObject model, ICompletionProposalAcceptor acceptor, ContentAssistContext context,
		String matchingPrefix) {
		val fd = model.getContainerOfType(FunctionDefinition)
		if (fd != null) {
			fillAllLocalVariables(fd.parameters?.parameters, acceptor, context, matchingPrefix, IMG_LOCAL_VAR)

			if (fd.returnParameters != null) {
				var mp = matchingPrefix
				if (!hasQualifier(mp))
					mp = ""

				val mpv = mp
				fd.returnParameters?.parameters?.forEach [
					if ((it.variable != null && it.variable.name.startsWith(mpv)) || hasQualifier(matchingPrefix))
						acceptor.accept(
							createCompletionProposal(matchingPrefix + it.variable.name, labelProvider.getText(it),
								labelProvider.getImage(IMG_LOCAL_VAR), context))

				]
			}
		}
	}

	/**
	 * Add the inner types as proposal.
	 */
	private def fillAllInnerTypes(EObject model, ICompletionProposalAcceptor acceptor, ContentAssistContext context,
		boolean includeEvents, String startText) {
		val allStructs = getAllStructs(model)
		val allEnums = getAllEnums(model)
		val allEvents = getAllEvents(model)

		var mp = startText
		if (!hasQualifier(mp))
			mp = ""

		val mpv = mp

		allStructs.forEach [
			if (it.name.startsWith(mpv))
				acceptor.accept(
					createCompletionProposal(it.name, labelProvider.getText(it), labelProvider.getImage(it), context));
		]
		allEnums.forEach [
			if (it.name.startsWith(mpv))
				acceptor.accept(
					createCompletionProposal(it.name, labelProvider.getText(it), labelProvider.getImage(it), context));
		]
		if (includeEvents) {
			allEvents.forEach [
				if (it.name.startsWith(mpv))
					acceptor.accept(
						createCompletionProposal(it.name, labelProvider.getText(it), labelProvider.getImage(it),
							context));
				]
			}
		}

		/**
		 * Fills all the not private members of the ContractOrLibrary containing the model.
		 */
		private def fillAllFieldsAndMethods(EObject model, ICompletionProposalAcceptor acceptor,
			ContentAssistContext context, String matchingPrefix) {
			if(model==null)return;
			 
			var cl = model.getContainerOfType(ContractOrLibrary)
			var ch = classHierarchy(cl)

			val allAllField = new HashSet
			val allMethods = new HashSet

			allAllField.addAll(cl.body?.variables.filter(StandardVariableDeclaration))
			allMethods.addAll(cl.body?.functions)
			ch.forEach [
				allAllField.addAll(it.body?.variables.filter(StandardVariableDeclaration).filter[!isPrivate(it)])
				allMethods.addAll(it.body?.functions.filter[!isPrivate(it)])
			]

			var mp = matchingPrefix
			if (!hasQualifier(mp))
				mp = ""

			val mpv = mp

			allAllField.forEach [
				if ((it.variable != null && it.variable.name.startsWith(mpv)) || hasQualifier(matchingPrefix))
					acceptor.accept(
						createCompletionProposal(mpv + it.variable.name, labelProvider.getText(it),
							labelProvider.getImage(it), context));
			]
			allMethods.forEach [
				if ((it != null && it.name != null && it.name.startsWith(mpv)) || hasQualifier(matchingPrefix))
					acceptor.accept(
						createCompletionProposal(mpv + it.name + "()", labelProvider.getText(it),
							labelProvider.getImage(it), context));
			]
		}

		/**
		 * Get all the local variables defined 
		 */
		private def Collection<? super Statement> getAllValidLocalStatements(Block s_block, Statement s_statement) {
			val Set<? super Statement> r_statements = new HashSet<Statement>
			if(s_block == null) return r_statements;

			var Block block = s_block
			var Statement statement = s_statement

			while (block != null) {
				var index = block.statements.indexOf(statement)
				var List<? super Statement> statements
				if (index != -1) {
					statements = new ArrayList(block.statements.subList(0, index))
				} else {
					statements = new ArrayList(block.statements)
				}

				if (block.eContainer instanceof ForStatement) {
					statements.add((block.eContainer as ForStatement))
				}

				statements.forEach [
					r_statements.add(it as Statement)
				]

				var b1 = block.eContainer.getContainerOfType(Block)
				if (b1 != null) { // move the blocks upward to collect the other lv
					block = b1
					statement = null
				} else {
					block = null;
				}
			}
			return r_statements
		}

		/**
		 * Added all fields and methods for the this expression.
		 */
		private def completeThisExpression_FieldOrMethod(EObject model, Assignment assignment,
			ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
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
				if (it.body != null) {
					allAllField.addAll(it.body.variables.filter(StandardVariableDeclaration))
					allMethods.addAll(it.body.functions)
				}
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
	