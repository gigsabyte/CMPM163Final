using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomPropertyDrawer(typeof(MathUtils.FloatRange))]
public class FloatRangeDrawer : PropertyDrawer
{
    // Draw the property inside the given rect
    public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
    {
        // Using BeginProperty / EndProperty on the parent property means that
        // prefab override logic works on the entire property.
        EditorGUI.BeginProperty(position, label, property);

        // Draw label
        position = EditorGUI.PrefixLabel(position, GUIUtility.GetControlID(FocusType.Passive), label);

        // Don't make child fields be indented
        var indent = EditorGUI.indentLevel;
        EditorGUI.indentLevel = 0;

        // Calculate rects
        var minLabelRect = new Rect(position.x, position.y, 25, position.height);
        var minRect = new Rect(position.x + 30, position.y, 50, position.height);
        var maxLabelRect = new Rect(position.x + 85, position.y, 25, position.height);
        var maxRect = new Rect(position.x + 120, position.y, 50, position.height);

        // Draw fields - pass GUIContent.none to each so they are drawn without labels
        EditorGUI.PrefixLabel(minLabelRect, new GUIContent("Min:"));
        EditorGUI.PropertyField(minRect, property.FindPropertyRelative("min"), GUIContent.none);
        EditorGUI.PrefixLabel(maxLabelRect, new GUIContent("Max:"));
        EditorGUI.PropertyField(maxRect, property.FindPropertyRelative("max"), GUIContent.none);

        // Set indent back to what it was
        EditorGUI.indentLevel = indent;

        EditorGUI.EndProperty();
    }
}
