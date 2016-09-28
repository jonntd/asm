#include "pushNode.h"
#include <maya/MPxDeformerNode.h>
#include <maya/MItGeometry.h>
#include <maya/MItMeshVertex.h>
#include <maya/MFnNumericAttribute.h>
#include <maya/MFnTypedAttribute.h>
#include <maya/MPoint.h>
#include <maya/MVector.h>
#include <maya/MGlobal.h>
#include <maya/MFnMesh.h>
#include <maya/MPointArray.h>
#include <maya/MFnDoubleArrayData.h>
#include <maya/MItMeshPolygon.h>

#include <maya/MPlug.h>

#include <set>
#include <asm.h>

#define SMALL (float)1e-6
#define BIG_DIST 99999

MTypeId     PushNode::id( 0x00108b1F); 

MObject PushNode::stressMap ;
MObject PushNode::useStress ;
MObject PushNode::amount;


PushNode::PushNode()
{
}

//creator funtion
void* PushNode::creator(){ return new PushNode(); }




MStatus PushNode::initialize()
{
	MFnNumericAttribute numericAttr;
	MFnTypedAttribute typedFn;
  
	useStress = numericAttr.create("useStress", "ust", MFnNumericData::kBoolean, 0);
	numericAttr.setKeyable(true);
	numericAttr.setStorable(true);
	addAttribute(useStress);

	amount = numericAttr.create("amount", "am", MFnNumericData::kDouble, 0);
	numericAttr.setKeyable(true);
	numericAttr.setStorable(true);
	addAttribute(amount);

	stressMap = typedFn.create("stressMap","str" ,MFnData::kDoubleArray);
	typedFn.setKeyable(true);
	typedFn.setWritable(true);
	typedFn.setStorable(true);
	addAttribute(stressMap);

	attributeAffects ( stressMap , outputGeom);
	attributeAffects ( amount , outputGeom);
	attributeAffects ( useStress , outputGeom);
	
	MGlobal::executeCommand("makePaintable -attrType multiFloat -sm deformer PushNode weights");

	return MStatus::kSuccess;
}

MStatus PushNode::deform( MDataBlock& data, MItGeometry& iter, 
						const MMatrix& localToWorldMatrix, 
						unsigned int mIndex )
{	
	
	 // Getting needed data
	 double envelopeV = data.inputValue(envelope).asFloat();
	 bool useStressV = data.inputValue(useStress).asBool();
	 double amountV = data.inputValue(amount).asDouble();

	 //If the useStress attr is turned on let s pull
	 //out the data of the stress map
	 MDoubleArray stressV;
	 if (useStressV == true)
	 {
		 //lets pull out the raw data as an MObject
		 MObject stressData = data.inputValue(stressMap).data();
		 //Now lets convert the row data to a double array
		 MFnDoubleArrayData stressDataFn(stressData);
		 stressV = stressDataFn.array();
	 }

	 //if envelop is zero do not compute
	 if (envelopeV < SMALL ) 
	 { return MS::kSuccess; }

	 //let s pull out all the points
	 MPointArray pos;
	 iter.allPositions(pos, MSpace::kWorld);
	
	 //now we need to acces the input mesh so we can create 
	 // a MeshFn instance
	 MArrayDataHandle meshH = data.inputArrayValue(input);
	 meshH.jumpToArrayElement(0);
	 MObject mesh = meshH.inputValue().child(inputGeom).asMesh();
	 MFnMesh meshFn(mesh);
	 
	 //let s pull out all at once the normals
	 MFloatVectorArray normals;
	 meshFn.getNormals(normals, MSpace::kWorld);



	 MPoint temp; 
	 for (int i=0; i< iter.exactCount(); i++)
	 {
		 
		 if( useStressV == true)
		 {
			pos[i] += (MVector(normals[i])*envelopeV*amountV*stressV[i]);
		 }
		 else
		 {
			//pos[i] += (MVector(normals[i])*envelopeV*amountV);
			push_no_stress_loop(&pos[0].x, &normals[0].x, amountV*envelopeV, iter.count());
		 }
		
	 }

	 //set all the positions
	iter.setAllPositions(pos);
	return MStatus::kSuccess ; 
}
