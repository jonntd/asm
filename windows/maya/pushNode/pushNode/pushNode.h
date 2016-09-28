#ifndef _PushNode
#define _PushNode
#include <maya/MPxDeformerNode.h>
#include <maya/MPoint.h>
#include <maya/MVector.h>
#include <maya/MFloatVector.h>
#include <maya/MMatrix.h>
#include <maya/MFnNumericAttribute.h>
#include <maya/MTypeId.h> 
#include <maya/MFnMatrixAttribute.h>
#include <maya/MEventMessage.h>
#include <maya/MNodeMessage.h>
#include <maya/MIntArray.h>
#include <maya/MPointArray.h>

#include <vector>
#include <set>


class PushNode : public MPxDeformerNode
{
public:
	PushNode();
	static  void*		creator();
	static  MStatus		initialize();
	virtual MStatus		deform(MDataBlock& data, MItGeometry& iter, const MMatrix& mat, unsigned int mIndex);


public :
	static  MTypeId		id;	
	static MObject		stressMap;
	static MObject		useStress;
	static MObject		amount;

  
};



#endif
