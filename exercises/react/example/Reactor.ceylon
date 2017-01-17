import ceylon.collection { HashMap, MutableMap }

class Reactor<Element>() given Element satisfies Object {
  shared abstract class Cell() {
    shared formal Element currentValue;
    variable Anything()[] propagates = [];
    variable Anything()[] fires = [];
    shared void addDependent(Anything() prop, Anything() fire) {
      propagates = propagates.withTrailing(prop);
      fires = fires.withTrailing(fire);
    }
    shared void propagateDependents() {
      for (f in propagates) {
        f();
      }
    }
    shared void fireDependentCallbacks() {
      for (f in fires) {
        f();
      }
    }
  }

  shared class InputCell(Element initialValue) extends Cell() {
    variable Element currentValue_ = initialValue;
    shared actual Element currentValue => currentValue_;
    assign currentValue {
      currentValue_ = currentValue;
      propagateDependents();
      fireDependentCallbacks();
    }
  }

  shared class ComputeCell extends Cell {
    shared alias Callback => Anything(Element);

    Element() newValue;

    shared new(Element() nv) extends Cell() {
      newValue = nv;
    }

    void propagate();
    void fireCallbacks();

    shared new single(Cell c, Element(Element) f) extends ComputeCell(() => f(c.currentValue)) {
      c.addDependent(propagate, fireCallbacks);
    }

    shared new double(Cell c1, Cell c2, Element(Element, Element) f) extends ComputeCell(() => f(c1.currentValue, c2.currentValue)) {
      //c1.addDependent(propagate, fireCallbacks);
      //c2.addDependent(propagate, fireCallbacks);
    }

    variable Element currentValue_ = newValue();
    shared actual Element currentValue => currentValue_;
    variable Element lastCallbackValue = currentValue_;

    variable Integer callbacksIssued = 0;
    variable MutableMap<Integer, Callback> activeCallbacks = HashMap<Integer, Callback>();

    shared interface Subscription {
      shared formal void cancel();
    }

    shared Subscription addCallback(Callback f) {
      value id = callbacksIssued;
      callbacksIssued++;
      activeCallbacks.put(id, f);
      return object satisfies Subscription {
        cancel() => activeCallbacks.remove(id);
      };
    }

    propagate = (() {
      Element nv = newValue();
      if (nv != currentValue) {
        currentValue_ = nv;
        propagateDependents();
      }
    });

    fireCallbacks = (() {
      if (lastCallbackValue == currentValue) {
        return;
      }
      lastCallbackValue = currentValue;
      for (cb in activeCallbacks.items) {
        cb(currentValue);
      }
      fireDependentCallbacks();
    });
  }
}
