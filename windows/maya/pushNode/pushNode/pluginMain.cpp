#include <maya/MGlobal.h>
#include <maya/MFnPlugin.h>

#include "pushNode.h"


// init
MStatus initializePlugin( MObject obj )
{ 
	MStatus   status;
	MFnPlugin plugin( obj );
    status = plugin.registerNode( "PushNode", PushNode::id, PushNode::creator,
                                PushNode::initialize, MPxNode::kDeformerNode);

   

	return status;
}

MStatus uninitializePlugin( MObject obj)
{
	MStatus   status;
	MFnPlugin plugin( obj );

    status = plugin.deregisterNode( PushNode::id );

    
    
   

	return status;
}
